import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _pickMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate());
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    
    bool isStockReport = _tabController.index == 0;
    String title = isStockReport ? "Laporan Mutasi Stok" : "Laporan Pengiriman";
    
    QuerySnapshot snapshot;
    if (isStockReport) {
      snapshot = await FirebaseFirestore.instance.collection('transactions').orderBy('date', descending: true).get();
    } else {
      snapshot = await FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).get();
    }

    var filteredDocs = snapshot.docs.where((doc) {
      Timestamp ts = doc[isStockReport ? 'date' : 'orderDate'];
      DateTime date = ts.toDate();
      return date.month == _selectedMonth.month && date.year == _selectedMonth.year;
    }).toList();

    if (filteredDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data untuk dicetak")));
      return;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Periode: ${DateFormat('MMMM yyyy').format(_selectedMonth)}", style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.purple),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
              },
              headers: isStockReport 
                  ? ['Tanggal', 'Barang', 'Qty', 'Keterangan (Supplier/Batch)']
                  : ['Tanggal', 'Resi', 'Status', 'Penerima & Barang'],
              
              data: filteredDocs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                
                if (isStockReport) {
                  bool isMasuk = data['type'] == 'IN';
                  String ket = isMasuk 
                      ? "Sup: ${data['supplier'] ?? '-'} | Batch: ${data['batch'] ?? '-'}"
                      : "Keluar (Shipping/Mutasi)";
                  
                  return [
                    DateFormat('dd/MM/yy HH:mm').format((data['date'] as Timestamp).toDate()),
                    data['productName'] ?? '-',
                    "${isMasuk ? '+' : '-'} ${data['qty']}",
                    ket,
                  ];
                } else {
                  return [
                    DateFormat('dd/MM/yy').format((data['orderDate'] as Timestamp).toDate()),
                    data['resi'] ?? '-',
                    (data['status'] ?? '-').toString().toUpperCase(),
                    "${data['receiverName']} (${data['productName']} x${data['qty']})",
                  ];
                }
              }).toList(),
            ),
            pw.Padding(padding: const pw.EdgeInsets.only(top: 20), child: pw.Text("Dicetak otomatis oleh Sistem Paketin Mobile")),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    String monthLabel = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan & Statistik"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.purple.shade100,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: "Mutasi Stok"),
            Tab(icon: Icon(Icons.local_shipping), text: "Riwayat Pengiriman"),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            label: Text(monthLabel, style: const TextStyle(color: Colors.white)),
          ),
          IconButton(
            onPressed: _generatePdf,
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: "Export PDF",
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStockReport(),
          _buildShippingReport(),
        ],
      ),
    );
  }

  Widget _buildStockReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs.where((doc) {
          DateTime date = (doc['date'] as Timestamp).toDate();
          return date.month == _selectedMonth.month && date.year == _selectedMonth.year;
        }).toList();

        if (docs.isEmpty) return const Center(child: Text("Tidak ada data."));

        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            bool isMasuk = data['type'] == 'IN';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isMasuk ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(isMasuk ? Icons.arrow_downward : Icons.arrow_upward, color: isMasuk ? Colors.green : Colors.red),
              ),
              title: Text(data['productName'] ?? '-'),
              subtitle: Text(_formatDate(data['date'])),
              trailing: Text("${isMasuk ? '+' : '-'} ${data['qty']}", style: TextStyle(fontWeight: FontWeight.bold, color: isMasuk ? Colors.green : Colors.red)),
            );
          },
        );
      },
    );
  }

  Widget _buildShippingReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs.where((doc) {
          DateTime date = (doc['orderDate'] as Timestamp).toDate();
          return date.month == _selectedMonth.month && date.year == _selectedMonth.year;
        }).toList();

        if (docs.isEmpty) return const Center(child: Text("Tidak ada data."));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.blue),
                title: Text("Resi: ${data['resi']}"),
                subtitle: Text("Status: ${data['status']}"),
                trailing: Text(_formatDate(data['orderDate'])),
              ),
            );
          },
        );
      },
    );
  }
}