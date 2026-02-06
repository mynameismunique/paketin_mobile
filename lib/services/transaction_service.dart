import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final CollectionReference _products = FirebaseFirestore.instance.collection('products');
  final CollectionReference _mutations = FirebaseFirestore.instance.collection('mutations');
  final CollectionReference _auditLogs = FirebaseFirestore.instance.collection('audit_logs');

  Future<void> mutationStock({
    required String productId,
    required String productName,
    required String source,
    required String dest,
    required int qty,
  }) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentReference productRef = _products.doc(productId);
      DocumentSnapshot snapshot = await transaction.get(productRef);

      if (!snapshot.exists) throw Exception("Produk tidak ditemukan!");

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> warehouseStocks = (data['warehouse_stocks'] as Map<String, dynamic>?) ?? {};

      int oldSourceStock = warehouseStocks[source] ?? 0;
      int oldDestStock = warehouseStocks[dest] ?? 0;

      int newSourceStock = oldSourceStock - qty;
      int newDestStock = oldDestStock + qty;

      warehouseStocks[source] = newSourceStock;
      warehouseStocks[dest] = newDestStock;

      transaction.update(productRef, {'warehouse_stocks': warehouseStocks});

      transaction.set(_mutations.doc(), {
        'productName': productName,
        'from': source,
        'to': dest,
        'qty': qty,
        'date': FieldValue.serverTimestamp(),
      });

      transaction.set(_auditLogs.doc(), {
        'activity': "Mutasi Gudang",
        'details': "Pindah $productName ($qty) : $source -> $dest",
        'user': "Admin",
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'warning',
      });
    });
  }
  
  Stream<QuerySnapshot> getProductsStream() {
    return _products.orderBy('name').snapshots();
  }
}