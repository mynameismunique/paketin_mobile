import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockController = TextEditingController();
  
  File? _selectedImage;
  String? _base64Image;

  String _selectedCategory = 'Umum';
  bool _isLoading = false;

  final List<String> _categories = ['Umum', 'Makanan', 'Minuman', 'Elektronik', 'Pecah Belah'];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 600,
    );

    if (photo != null) {
      File imageFile = File(photo.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      
      setState(() {
        _selectedImage = imageFile;
        _base64Image = base64Encode(imageBytes);
      });
    }
  }


  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ambil Gambar Dari:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sourceButton(Icons.camera_alt, "Kamera", ImageSource.camera),
                  _sourceButton(Icons.photo_library, "Galeri", ImageSource.gallery),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _sourceButton(IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('products').add({
          'name': _nameController.text,
          'sku': _skuController.text,
          'category': _selectedCategory,
          'stock': int.parse(_stockController.text),
          'imageBase64': _base64Image,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Barang berhasil disimpan!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal simpan: $e"), backgroundColor: Colors.red),
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
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tambah Barang Baru"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AREA UPLOAD FOTO ---
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Center(
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      image: _selectedImage != null 
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                    ),
                    child: _selectedImage == null 
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.blue[300]),
                            const SizedBox(height: 10),
                            Text("Upload Foto Barang", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                          ],
                        )
                      : null, // Kalau ada gambar, child kosong
                  ),
                ),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _nameController,
                decoration: _inputStyle("Nama Barang", Icons.inventory_2),
                validator: (val) => val!.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _skuController,
                decoration: _inputStyle("Kode SKU / Barcode", Icons.qr_code),
                validator: (val) => val!.isEmpty ? "SKU wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: _inputStyle("Kategori", Icons.category),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: _inputStyle("Jumlah Stok Awal", Icons.numbers),
                validator: (val) => val!.isEmpty ? "Stok wajib diisi" : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveItem,
                  icon: const Icon(Icons.save),
                  label: Text(
                    _isLoading ? "Menyimpan..." : "SIMPAN DATA",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
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