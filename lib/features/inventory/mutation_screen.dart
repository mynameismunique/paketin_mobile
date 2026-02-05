import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MutationScreen extends StatefulWidget {
  const MutationScreen({super.key});

  @override
  State<MutationScreen> createState() => _MutationScreenState();
}

class _MutationScreenState extends State<MutationScreen> {
  String? _selectedProductDocId;
  String? _selectedProductName;
  String? _sourceWarehouse;
  String? _destWarehouse;
  final TextEditingController _qtyController = TextEditingController();
  
  final List<String> _warehouses = ['Gudang Pusat', 'Gudang Bandung', 'Gudang Surabaya', 'Gudang Medan'];

  Future<void> _submitMutation() async {
    if (_selectedProductDocId == null || _sourceWarehouse == null || _destWarehouse == null || _qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi semua data")));
      return;
    }

    if (_sourceWarehouse == _destWarehouse) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gudang asal dan tujuan tidak boleh sama!"), backgroundColor: Colors.red));
      return;
    }

    int qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jumlah harus lebih dari 0")));
      return;
    }

    try {
      DocumentReference productRef = FirebaseFirestore.instance.collection('products').doc(_selectedProductDocId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(productRef);
        if (!snapshot.exists) throw Exception("Produk tidak ditemukan!");

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> warehouseStocks = (data['warehouse_stocks'] as Map<String, dynamic>?) ?? {};

        String source = _sourceWarehouse!;
        String dest = _destWarehouse!;
        
        int oldSourceStock = warehouseStocks[source] ?? 0;
        int oldDestStock = warehouseStocks[dest] ?? 0;

        int newSourceStock = oldSourceStock - qty;
        int newDestStock = oldDestStock + qty;

        warehouseStocks[source] = newSourceStock;
        warehouseStocks[dest] = newDestStock;

        transaction.update(productRef, {'warehouse_stocks': warehouseStocks});

        transaction.set(FirebaseFirestore.instance.collection('mutations').doc(), {
          'productName': _selectedProductName,
          'from': source,
          'to': dest,
          'qty': qty,
          'date': FieldValue.serverTimestamp(),
        });

        transaction.set(FirebaseFirestore.instance.collection('audit_logs').doc(), {
          'activity': "Mutasi Gudang",
          'details': "Pindah $_selectedProductName ($qty) : $source -> $dest",
          'user': "Admin",
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'warning',
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mutasi Berhasil!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800], 
      appBar: AppBar(
        title: const Text("Mutasi Antar Gudang"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pindahkan Barang", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("Transfer stok antar lokasi gudang", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
                      builder: (context, snapshot) {
                        List<DropdownMenuItem<String>> items = [];
                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            items.add(DropdownMenuItem(
                              value: doc.id,
                              child: Text(data['name'], overflow: TextOverflow.ellipsis),
                              onTap: () => setState(() => _selectedProductName = data['name']),
                            ));
                          }
                        }
                        return _modernDropdownField("Pilih Barang", Icons.inventory_2, _selectedProductDocId, items, (val) {
                          setState(() => _selectedProductDocId = val);
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _modernDropdownField(
                            "Dari", 
                            Icons.store_mall_directory, 
                            _sourceWarehouse, 
                            _warehouses.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12)))).toList(), // Font diperkecil dikit
                            (val) => setState(() => _sourceWarehouse = val)
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_forward, color: Colors.grey),
                        ),

                        Expanded(
                          child: _modernDropdownField(
                            "Ke", 
                            Icons.store, 
                            _destWarehouse, 
                            _warehouses.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12)))).toList(), 
                            (val) => setState(() => _destWarehouse = val)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.numbers, color: Colors.grey),
                        labelText: "Jumlah Transfer",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _submitMutation,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text("MUTASI STOK"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernDropdownField(String label, IconData icon, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}