import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  int _selectedTabIndex = 0; 
  String _searchQuery = "";
  bool _isUploading = false;

  final List<String> _tabStatus = ['Dikemas', 'Dikirim', 'Sampai'];

  User? user = FirebaseAuth.instance.currentUser;
  bool get isAdmin => user?.email == 'admin@paketin.com';

  void _takeTask(String docId) {
    FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': 'Dikirim'});
    
    FirebaseFirestore.instance.collection('audit_logs').add({
      'activity': "Pengantaran Dimulai",
      'details': "Paket (ID: $docId) dibawa kurir.",
      'user': "Kurir",
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'info',
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tugas diambil! Hati-hati di jalan.")));
  }

  void _showCompletionDialog(BuildContext context, String docId) {
    final picker = ImagePicker();
    File? tempImage; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Text("Bukti Pengantaran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Foto paket di lokasi penerima", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () async {
                      final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 20, maxWidth: 500);
                      if (photo != null) {
                        setModalState(() => tempImage = File(photo.path));
                      }
                    },
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        image: tempImage != null 
                          ? DecorationImage(image: FileImage(tempImage!), fit: BoxFit.cover)
                          : null
                      ),
                      child: tempImage == null 
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_rounded, size: 50, color: Colors.blue[300]), const Text("Ketuk Kamera")])
                        : null,
                    ),
                  ),
                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: (tempImage == null || _isUploading)
                      ? null 
                      : () async {
                          Navigator.pop(ctx); 
                          await _processCompletion(docId, tempImage!);
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text(_isUploading ? "MENGIRIM..." : "KONFIRMASI SELESAI", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _processCompletion(String docId, File imageFile) async {
    setState(() => _isUploading = true);
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('orders').doc(docId).update({
        'status': 'Sampai',
        'proofImage': base64Image,
        'completedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('audit_logs').add({
        'activity': "Paket Sampai",
        'details': "Paket (ID: $docId) sukses diantar.",
        'user': "Kurir",
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'success',
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paket Selesai! Kerja bagus."), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isAdmin ? "Pantau Logistik (Admin)" : "Daftar Tugas Kurir", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari Resi atau Penerima...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildTabButton(0, "Pesanan Baru", Icons.inventory_2_outlined),
                const SizedBox(width: 10),
                _buildTabButton(1, "Dalam Pengiriman", Icons.local_shipping_outlined),
                const SizedBox(width: 10),
                _buildTabButton(2, "Selesai", Icons.check_circle_outline),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isEqualTo: _tabStatus[_selectedTabIndex])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                var allDocs = snapshot.data?.docs ?? [];
                
                var filteredDocs = allDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String resi = (data['resi'] ?? '').toString().toLowerCase();
                  String receiver = (data['receiverName'] ?? '').toString().toLowerCase();
                  return resi.contains(_searchQuery) || receiver.contains(_searchQuery);
                }).toList();

                filteredDocs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp t1 = dataA['orderDate'] ?? Timestamp.now();
                  Timestamp t2 = dataB['orderDate'] ?? Timestamp.now();
                  return t2.compareTo(t1);
                });

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("Tidak ada data di tab ini", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildOrderCard(data, filteredDocs[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> data, String docId) {
    String status = data['status'] ?? '-';
    Color statusColor = status == 'Dikemas' ? Colors.blue : (status == 'Dikirim' ? Colors.orange : Colors.green);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 16, color: statusColor),
                    const SizedBox(width: 5),
                    Text(data['resi'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
                Text(_formatDate(data['orderDate']), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['receiverName'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(data['address'] ?? '-', style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text("${data['productName']} (${data['qty']} Unit)", style: const TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(5)),
                      child: Text(data['shippingMethod'] ?? 'Regular', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),

                if (status == 'Dikemas') ...[
                  if (isAdmin) 
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("Menunggu Kurir Mengambil Paket", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                    )
                  else 
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _takeTask(docId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.motorcycle, size: 18),
                        label: const Text("Ambil Pengiriman"),
                      ),
                    )
                ]
                else if (status == 'Dikirim') ...[
                  if (isAdmin)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("Sedang Diantar Kurir...", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCompletionDialog(context, docId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text("Selesaikan Order"),
                      ),
                    )
                ]
                else if (status == 'Sampai' && data['proofImage'] != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(context: context, builder: (ctx) => Dialog(
                          child: Image.memory(base64Decode(data['proofImage']), fit: BoxFit.contain)
                        ));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.image, size: 18),
                      label: const Text("Lihat Bukti Foto"),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    return DateFormat('dd MMM, HH:mm').format(timestamp.toDate());
  }
}