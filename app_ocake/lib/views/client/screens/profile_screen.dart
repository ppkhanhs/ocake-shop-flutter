import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = 'Lầu Trí Kiệt';
  String _phone = '0327749747';
  String _address = '140 Lê Trọng Tấn, TP.HCM';
  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  void _updateProfile() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thông tin thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _image == null
                              ? const AssetImage('assets/default_avatar.png') as ImageProvider
                              : FileImage(_image!),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    initialValue: _name,
                    labelText: 'Họ và tên',
                    onSaved: (value) => _name = value!,
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 15),
                  _buildTextFormField(
                    initialValue: _phone,
                    labelText: 'Số điện thoại',
                    keyboardType: TextInputType.phone,
                    onSaved: (value) => _phone = value!,
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 15),
                  _buildTextFormField(
                    initialValue: _address,
                    labelText: 'Địa chỉ',
                    onSaved: (value) => _address = value!,
                    validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    icon: Icons.home,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40), // Tăng padding ngang
                    ),
                    onPressed: _updateProfile,
                    child: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String labelText,
    String? initialValue,
    TextInputType? keyboardType,
    bool obscureText = false,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    IconData? icon,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onSaved: onSaved,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }
}