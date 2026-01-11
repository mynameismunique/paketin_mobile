import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_item_screen.dart';
import 'add_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final List<String> _categories = ['Semua', 'Umum', 'Makanan', 'Minuman', 'Elektronik', 'Pecah Belah'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Gudang & Lokasi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddItemScreen()));
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Barang Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Cari barang...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      bool isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) => setState(() => _selectedCategory = category),
                          selectedColor: Colors.blueAccent,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _emptyState();

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = data['name'].toString().toLowerCase();
                  String sku = data['sku'].toString().toLowerCase();
                  String category = data['category'] ?? 'Umum';
                  return (name.contains(_searchQuery) || sku.contains(_searchQuery)) && 
                         (_selectedCategory == 'Semua' || category == _selectedCategory);
                }).toList();

                if (filteredDocs.isEmpty) return _emptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var product = filteredDocs[index];
                    var data = product.data() as Map<String, dynamic>;
                    var docId = product.id;
                    int totalStock = data['stock'] ?? 0;
                    
                    Map<String, dynamic> locations = (data['warehouse_stocks'] as Map<String, dynamic>?) ?? {};
                    
                    if (locations.isEmpty && totalStock > 0) {
                      locations = {'Gudang Pusat': totalStock};
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text(data['name'][0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue))),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("SKU: ${data['sku']} • ${data['category']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditItemScreen(docId: docId, data: data)));
                                  } else if (value == 'delete') {
                                    _deleteItem(context, docId, data['name']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20, color: Colors.blue), SizedBox(width: 10), Text("Edit")])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 10), Text("Hapus")])),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 15),
                          const Divider(),
                          const SizedBox(height: 5),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Stok:", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text("$totalStock Unit", style: TextStyle(fontWeight: FontWeight.bold, color: totalStock > 0 ? Colors.green : Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: locations.entries.map((entry) {
                              if (entry.value == 0) return const SizedBox.shrink();
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.store, size: 14, color: Colors.orange),
                                    const SizedBox(width: 5),
                                    Text("${entry.key}: ", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                    Text("${entry.value}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Barang tidak ditemukan", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  void _deleteItem(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Barang?"),
        content: Text("Yakin ingin menghapus '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('products').doc(docId).delete();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Barang dihapus")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}