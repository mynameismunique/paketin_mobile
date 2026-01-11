import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MutationScreen extends StatefulWidget {
  const MutationScreen({super.key});

  @override
  State<MutationScreen> createState() => _MutationScreenState();
}

class _MutationScreenState extends State<MutationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  
  final List<String> _warehouses = ['Gudang Pusat', 'Gudang Bandung', 'Gudang Surabaya'];

  String? _selectedProductDocId;
  String? _selectedProductName;
  String? _sourceWarehouse;
  String? _destWarehouse;

  int _currentSourceStock = 0; 
  bool _isLoading = false;

  Future<void> _submitMutation() async {
    if (_formKey.currentState!.validate()) {
      String source = _sourceWarehouse!; 
      String dest = _destWarehouse!;

      if (source == dest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gudang asal dan tujuan tidak boleh sama!"), backgroundColor: Colors.orange),
        );
        return;
      }

      int qty = int.parse(_qtyController.text);

      if (qty > _currentSourceStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Stok di $source cuma $_currentSourceStock!"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

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
            'details': "Memindahkan $_selectedProductName ($qty unit) dari $source ke $dest",
            'user': "Admin",
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'warning',
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mutasi Berhasil!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _modernInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mutasi Antar Gudang"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pindahkan Barang", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text("Transfer stok antar lokasi gudang", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  
                  List<DropdownMenuItem<String>> items = [];
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    items.add(DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name']),
                      onTap: () {
                        setState(() {
                          _selectedProductName = data['name'];
                          var stocks = data['warehouse_stocks'] as Map<String, dynamic>? ?? {};
                          if (stocks.isEmpty && _sourceWarehouse == 'Gudang Pusat') {
                             _currentSourceStock = data['stock'] ?? 0; 
                          } else if (_sourceWarehouse != null) {
                             _currentSourceStock = stocks[_sourceWarehouse] ?? 0;
                          }
                        });
                      },
                    ));
                  }
                  return DropdownButtonFormField<String>(
                    decoration: _modernInput("Pilih Barang", Icons.inventory_2),
                    items: items,
                    value: _selectedProductDocId,
                    onChanged: (val) => setState(() => _selectedProductDocId = val),
                    validator: (val) => val == null ? "Wajib pilih barang" : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _modernInput("Dari", Icons.store_mall_directory),
                      value: _sourceWarehouse,
                      items: _warehouses.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setState(() {
                        _sourceWarehouse = val;
                      }),
                      validator: (val) => val == null ? "Wajib" : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_forward, color: Colors.grey),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _modernInput("Ke", Icons.store),
                      value: _destWarehouse,
                      items: _warehouses.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setState(() => _destWarehouse = val),
                      validator: (val) => val == null ? "Wajib" : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              if (_sourceWarehouse != null && _selectedProductDocId != null)
                Text("Stok di $_sourceWarehouse: $_currentSourceStock unit", 
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: _modernInput("Jumlah Transfer", Icons.onetwothree),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(_isLoading ? "Memindahkan..." : "MUTASI STOK"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _submitMutation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}