import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierService {
  final CollectionReference _suppliers = FirebaseFirestore.instance.collection('suppliers');

  Stream<QuerySnapshot> getSuppliersStream() {
    return _suppliers.orderBy('name').snapshots();
  }

  Future<void> addSupplier(Map<String, dynamic> data) async {
    await _suppliers.add(data);
  }

  Future<void> updateSupplier(String docId, Map<String, dynamic> data) async {
    await _suppliers.doc(docId).update(data);
  }

  Future<void> deleteSupplier(String docId) async {
    await _suppliers.doc(docId).delete();
  }
}