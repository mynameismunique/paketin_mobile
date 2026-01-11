import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatelessWidget {
  final bool isAdmin;

  const NotificationScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? "Notifikasi Admin" : "Info Kurir"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          
          if (isAdmin) ...[
            const Text("Peringatan Stok (Low Stock)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').where('stock', isLessThanOrEqualTo: 5).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var docs = snapshot.data!.docs;
                
                if (docs.isEmpty) {
                  return _emptyCard("Stok Aman! Tidak ada yang menipis.", Icons.check_circle, Colors.green);
                }

                return Column(
                  children: docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        title: Text("Stok Menipis: ${data['name']}"),
                        subtitle: Text("Sisa stok: ${data['stock']} unit. Segera Restock!"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 25),
          ],

          if (!isAdmin) ...[
            const Text("Tugas Tersedia (Order Baru)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'Dikemas').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                var docs = snapshot.data!.docs;
                
                if (docs.isEmpty) {
                  return _emptyCard("Tidak ada order baru.", Icons.coffee, Colors.brown);
                }

                return Column(
                  children: docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.blue.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.new_releases, color: Colors.blue),
                        title: Text("Order Baru: ${data['resi']}"),
                        subtitle: Text("Tujuan: ${data['address']}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
             const SizedBox(height: 25),
          ],

          Text(isAdmin ? "Aktivitas Pengiriman Terbaru" : "Status Paket Anda", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').orderBy('orderDate', descending: true).limit(5).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              var docs = snapshot.data!.docs;

              return Column(
                children: docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'] ?? '-';
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.local_shipping, color: status == 'Sampai' ? Colors.green : Colors.orange),
                      title: Text("Resi: ${data['resi']}"),
                      subtitle: Text("Status: ${status.toUpperCase()}"),
                      trailing: const Text("Update", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}