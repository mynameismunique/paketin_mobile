import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class TransactionScreen extends StatefulWidget {
  final bool isMasuk;

  const TransactionScreen({super.key, required this.isMasuk});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _qtyController = TextEditingController();
  final _batchController = TextEditingController(); 
  final _expiredController = TextEditingController(); 
  
  final _receiverController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedDocId;
  String? _selectedName;
  int _currentStock = 0;
  bool _isLoading = false;
  DateTime? _selectedExpiredDate; 
  String? _selectedShippingMethod;
  
  String? _selectedSupplier;

  final List<String> _shippingMethods = ['Regular', 'Express', 'Same Day', 'Cargo'];

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)), 
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedExpiredDate = picked;
        _expiredController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  String _generateResi() {
    var rng = Random();
    return "PKT-${rng.nextInt(90000) + 10000}";
  }

 Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate() && _selectedDocId != null) {
      setState(() => _isLoading = true);
      int qty = int.parse(_qtyController.text);
      
      try {
        if (!widget.isMasuk && qty > _currentStock) {
          throw "Stok tidak cukup! Sisa stok: $_currentStock";
        }

        int newStock = widget.isMasuk ? (_currentStock + qty) : (_currentStock - qty);
        
        await FirebaseFirestore.instance.collection('products').doc(_selectedDocId).update({
          'stock': newStock,
        });

        if (widget.isMasuk) {
          await FirebaseFirestore.instance.collection('transactions').add({
            'type': 'IN',
            'productName': _selectedName,
            'qty': qty,
            'supplier': _selectedSupplier,
            'batch': _batchController.text,       
            'expiredDate': _selectedExpiredDate,  
            'date': FieldValue.serverTimestamp(),
          });
        } else {
          await FirebaseFirestore.instance.collection('orders').add({
            'resi': _generateResi(),
            'productName': _selectedName,
            'qty': qty,
            'receiverName': _receiverController.text,
            'address': _addressController.text,
            'shippingMethod': _selectedShippingMethod,
            'status': 'Dikemas', 
            'orderDate': FieldValue.serverTimestamp(),
            'courierId': '',
          });
        }

        await FirebaseFirestore.instance.collection('audit_logs').add({
          'activity': widget.isMasuk ? "Restock Barang" : "Membuat Order Pengiriman",
          'details': widget.isMasuk 
              ? "Menambah stok $_selectedName ($qty unit) dari $_selectedSupplier"
              : "Mengirim $_selectedName ($qty unit) ke ${_receiverController.text}",
          'user': "Admin",
          'timestamp': FieldValue.serverTimestamp(),
          'type': widget.isMasuk ? 'success' : 'info',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data Berhasil Disimpan!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedDocId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih barang terlebih dahulu"), backgroundColor: Colors.orange),
      );
    }
  }

  InputDecoration _modernInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = widget.isMasuk ? Colors.green : Colors.orange;
    String title = widget.isMasuk ? "Restock Gudang (Masuk)" : "Kirim Paket (Keluar)";
    bool isRestock = widget.isMasuk; 

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: themeColor, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Detail Barang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  
                  List<DropdownMenuItem<String>> items = [];
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    items.add(DropdownMenuItem(
                      value: doc.id,
                      child: Text("${data['name']} (Sisa: ${data['stock']})"),
                      onTap: () {
                        setState(() {
                          _selectedName = data['name'];
                          _currentStock = data['stock'];
                        });
                      },
                    ));
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedDocId,
                    items: items,
                    onChanged: (val) => setState(() => _selectedDocId = val),
                    decoration: _modernInput("Pilih Barang", Icons.inventory_2),
                    validator: (val) => val == null ? "Wajib dipilih" : null,
                  );
                },
              ),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: _modernInput("Jumlah Unit", Icons.numbers),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),

              if (isRestock) ...[
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                const Text("Data Batch & Expired", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('suppliers').orderBy('name').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    
                    List<DropdownMenuItem<String>> supplierItems = [];
                    for (var doc in snapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      supplierItems.add(DropdownMenuItem(
                        value: data['name'],
                        child: Text(data['name']),
                      ));
                    }

                    if (supplierItems.isEmpty) {
                      return const Text("Belum ada Supplier. Tambahkan di menu Data Supplier dulu.", style: TextStyle(color: Colors.red));
                    }

                    return DropdownButtonFormField<String>(
                      decoration: _modernInput("Pilih Supplier", Icons.store),
                      value: _selectedSupplier,
                      items: supplierItems,
                      onChanged: (val) => setState(() => _selectedSupplier = val),
                      validator: (val) => val == null ? "Wajib pilih supplier" : null,
                    );
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _batchController,
                  decoration: _modernInput("Nomor Batch", Icons.qr_code),
                  validator: (val) => val!.isEmpty ? "Batch wajib diisi" : null, 
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _expiredController,
                  readOnly: true, 
                  onTap: _pickDate, 
                  decoration: _modernInput("Tanggal Expired", Icons.calendar_today),
                  validator: (val) => val!.isEmpty ? "Expired date wajib diisi" : null, 
                ),
              ],

              if (!isRestock) ...[
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                const Text("Detail Pengiriman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _receiverController,
                  decoration: _modernInput("Nama Penerima", Icons.person),
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: _modernInput("Alamat Lengkap", Icons.location_on),
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  decoration: _modernInput("Metode Kirim", Icons.local_shipping),
                  value: _selectedShippingMethod,
                  items: _shippingMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setState(() => _selectedShippingMethod = val),
                  validator: (val) => val == null ? "Wajib pilih metode" : null,
                ),
              ],

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitTransaction,
                  icon: Icon(isRestock ? Icons.save : Icons.local_shipping), 
                  label: Text(_isLoading ? "Memproses..." : "SIMPAN DATA"),
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}