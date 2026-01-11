import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Arsip Pengiriman", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari Resi, Penerima, atau Alamat...",
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isEqualTo: 'Sampai') 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var docs = snapshot.data?.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String resi = (data['resi'] ?? '').toString().toLowerCase();
                  String receiver = (data['receiverName'] ?? '').toString().toLowerCase();
                  String address = (data['address'] ?? '').toString().toLowerCase();
                  return resi.contains(_searchQuery) || receiver.contains(_searchQuery) || address.contains(_searchQuery);
                }).toList() ?? [];

                docs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp t1 = dataA['completedAt'] ?? Timestamp.now();
                  Timestamp t2 = dataB['completedAt'] ?? Timestamp.now();
                  return t2.compareTo(t1); 
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 15),
                        Text("Belum ada riwayat selesai", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildHistoryCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data) {
    String? proofBase64 = data['proofImage'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text("SELESAI", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], letterSpacing: 1)),
                  ],
                ),
                Text(_formatDate(data['completedAt']), style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("No. Resi", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(height: 2),
                        Text(data['resi'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[200]),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Penerima", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(height: 2),
                        Text(data['receiverName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 10),

                _infoRow(Icons.inventory_2_outlined, "${data['productName']} (${data['qty']} Unit)"),
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_outlined, data['address'] ?? '-'),

                const SizedBox(height: 20),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      backgroundColor: Colors.grey[50],
                      collapsedBackgroundColor: Colors.blueAccent.withOpacity(0.05),
                      title: const Text("Lihat Bukti Foto", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      leading: const Icon(Icons.image, color: Colors.blueAccent),
                      childrenPadding: const EdgeInsets.all(10),
                      children: [
                        if (proofBase64 != null && proofBase64.isNotEmpty)
                          _buildSafeImage(proofBase64)
                        else
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("Foto tidak tersedia", style: TextStyle(color: Colors.grey)),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.2))),
      ],
    );
  }

  Widget _buildSafeImage(String base64String) {
    try {
      Uint8List bytes = base64Decode(base64String);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 150, color: Colors.grey[200],
            child: const Center(child: Text("Gagal memuat gambar", style: TextStyle(fontSize: 12))),
          ),
        ),
      );
    } catch (e) {
      return const Text("Format gambar rusak", style: TextStyle(color: Colors.red, fontSize: 10));
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "-";
    return DateFormat('dd MMM yyyy • HH:mm').format(timestamp.toDate());
  }
}