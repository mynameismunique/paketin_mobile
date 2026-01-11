import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditItemScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditItemScreen({super.key, required this.docId, required this.data});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;
  String _selectedCategory = 'Umum';
  bool _isLoading = false;

  final List<String> _categories = ['Umum', 'Makanan', 'Minuman', 'Elektronik', 'Pecah Belah'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['name']);
    _skuController = TextEditingController(text: widget.data['sku']);
    _stockController = TextEditingController(text: widget.data['stock'].toString());
    _selectedCategory = widget.data['category'] ?? 'Umum';
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('products').doc(widget.docId).update({
          'name': _nameController.text,
          'sku': _skuController.text,
          'category': _selectedCategory,
          'stock': int.parse(_stockController.text),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data berhasil diperbarui!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Barang")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nama Barang", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: "SKU", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedCategory) ? _selectedCategory : 'Umum',
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stok", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateItem,
                  icon: const Icon(Icons.save_as),
                  label: Text(_isLoading ? "Menyimpan..." : "UPDATE DATA"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}