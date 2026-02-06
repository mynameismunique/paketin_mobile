import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryService {
  final CollectionReference _orders = FirebaseFirestore.instance.collection('orders');
  final CollectionReference _auditLogs = FirebaseFirestore.instance.collection('audit_logs');

  Stream<QuerySnapshot> getOrdersByStatus(String status) {
    return _orders.where('status', isEqualTo: status).snapshots();
  }

  Future<void> takeTask(String docId) async {
    await _orders.doc(docId).update({'status': 'Dikirim'});
    
    await _auditLogs.add({
      'activity': "Pengantaran Dimulai",
      'details': "Kurir membawa paket (ID: $docId)",
      'user': "Kurir",
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'info',
    });
  }

  Future<void> completeTask(String docId, String base64Image) async {
    await _orders.doc(docId).update({
      'status': 'Sampai',
      'proofImage': base64Image,
      'completedAt': FieldValue.serverTimestamp(),
    });

    await _auditLogs.add({
      'activity': "Paket Sampai",
      'details': "Paket (ID: $docId) sukses diantar.",
      'user': "Kurir",
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'success',
    });
  }
}