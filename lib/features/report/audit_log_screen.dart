import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Audit Log System"), 
        backgroundColor: Colors.blueGrey, 
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('audit_logs').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("Belum ada aktivitas terekam.", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              
              String type = data['type'] ?? 'info';
              Color color;
              IconData icon;

              if (type == 'success') {
                color = Colors.green;
                icon = Icons.check_circle_outline;
              } else if (type == 'warning') {
                color = Colors.orange;
                icon = Icons.swap_horiz;
              } else {
                color = Colors.blue;
                icon = Icons.info_outline;
              }

              Timestamp? ts = data['timestamp'];
              String time = ts != null ? DateFormat('dd MMM HH:mm').format(ts.toDate()) : '-';

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200)
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(data['activity'] ?? 'Aktivitas', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(data['details'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text("${data['user']} • $time", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}