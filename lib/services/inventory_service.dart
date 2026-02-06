import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryService {
  final CollectionReference _products = FirebaseFirestore.instance.collection('products');

  Stream<QuerySnapshot> getProductsStream() {
    return _products.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> searchProducts(String query, String category) {
    return _products.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    await _products.add(data);
  }

  Future<void> updateProduct(String docId, Map<String, dynamic> data) async {
    await _products.doc(docId).update(data);
  }

  Future<void> deleteProduct(String docId) async {
    await _products.doc(docId).delete();
  }
}