import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';

class EditItemScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditItemScreen({super.key, required this.docId, required this.data});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final InventoryService _inventoryService = InventoryService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;
  
  String _selectedCategory = 'Umum';
  bool _isLoading = false;

  final List<String> _categories = ['Umum', 'Makanan', 'Minuman', 'Elektronik', 'Pecah Belah'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['name']);
    _skuController = TextEditingController(text: widget.data['sku']);
    _stockController = TextEditingController(text: widget.data['stock'].toString());
    _imageController = TextEditingController(text: widget.data['imageUrl'] ?? ''); // Load Link Gambar
    _selectedCategory = widget.data['category'] ?? 'Umum';
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // 3. Panggil Service untuk Update
        await _inventoryService.updateProduct(widget.docId, {
          'name': _nameController.text,
          'sku': _skuController.text,
          'category': _selectedCategory,
          'stock': int.parse(_stockController.text),
          'imageUrl': _imageController.text, // Update Link Gambar
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

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Data Barang"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _imageController.text.isEmpty
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                              Text("Tidak ada gambar", style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          )
                        : Image.network(
                            _imageController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.broken_image, color: Colors.red));
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _imageController,
                decoration: _inputStyle("Link Gambar (URL)", Icons.link),
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nameController,
                decoration: _inputStyle("Nama Barang", Icons.inventory_2),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _skuController,
                decoration: _inputStyle("Kode SKU", Icons.qr_code),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedCategory) ? _selectedCategory : 'Umum',
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: _inputStyle("Kategori", Icons.category),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: _inputStyle("Stok Saat Ini", Icons.numbers),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _updateItem,
                  icon: const Icon(Icons.save_as),
                  label: Text(
                    _isLoading ? "Menyimpan..." : "UPDATE DATA",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}