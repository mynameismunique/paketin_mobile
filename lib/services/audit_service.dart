import 'package:cloud_firestore/cloud_firestore.dart';

class AuditService {
  final CollectionReference _logs = FirebaseFirestore.instance.collection('audit_logs');

  Stream<QuerySnapshot> getLogsStream() {
    return _logs.orderBy('timestamp', descending: true).snapshots();
  }
}