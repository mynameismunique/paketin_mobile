import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getProductCountStream() {
    return _db.collection('products').snapshots();
  }

  Stream<QuerySnapshot> getOrderCountStream(String status) {
    return _db.collection('orders').where('status', isEqualTo: status).snapshots();
  }

  Stream<QuerySnapshot> getTransactionCountStream(String type) {
    return _db.collection('transactions').where('type', isEqualTo: type).snapshots();
  }
}