import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  AddEditProductScreen({this.product});

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['name'] ?? '');
    _priceController = TextEditingController(
        text: widget.product != null ? widget.product!['price'].toString() : '');
    _descriptionController = TextEditingController(text: widget.product?['description'] ?? '');
    _imageUrl = widget.product?['image'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null; // Xoá link cũ nếu người dùng chọn ảnh mới
      });
    }
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = {
        'name': _nameController.text,
        'price': int.tryParse(_priceController.text) ?? 0,
        'image': _imageFile?.path ?? _imageUrl ?? '',
        'description': _descriptionController.text,
      };
      Navigator.pop(context, product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa bánh' : 'Thêm bánh mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : (_imageUrl != null && _imageUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: _imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty)
                      ? Center(child: Text('Nhấn để chọn ảnh'))
                      : null,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Tên bánh'),
                validator: (value) => value!.isEmpty ? 'Nhập tên bánh' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Giá bánh'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Nhập giá' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Mô tả sản phẩm'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Nhập mô tả' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
