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
  String _name = 'Nguyễn Văn A';
  String _phone = '0123456789';
  String _address = '123 Đường ABC, Quận 1';
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
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
          content: Text('Đang cập nhật...'),
          duration: Duration(seconds: 1),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thông tin thành công')),
          );
        }
      });
    }
  }

  void _logout() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pinkAccent, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade100.withOpacity(0.8),
              Colors.orange.shade100.withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 24.0,
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Center(
                    child: Stack(
                      alignment: Alignment.center, // Đặt icon vào giữa
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.7),
                          backgroundImage:
                              _image == null
                                  ? const AssetImage(
                                        'assets/default_avatar.png',
                                      )
                                      as ImageProvider
                                  : FileImage(_image!),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            iconSize: 30,
                            tooltip: 'Chọn ảnh đại diện',
                            onPressed: _pickImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildTextFormField(
                    initialValue: _name,
                    labelText: 'User Name',
                    onSaved: (value) => _name = value!,
                    validator:
                        (value) => value!.isEmpty ? 'Vui lòng nhập tên' : null,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildTextFormField(
                    initialValue: _phone,
                    labelText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    onSaved: (value) => _phone = value!,
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Vui lòng nhập số điện thoại'
                                : null,
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildTextFormField(
                    initialValue: _address,
                    labelText: 'Address',
                    onSaved: (value) => _address = value!,
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 25),

                  _buildTextFormField(
                    labelText: 'Current Password',
                    obscureText: true,
                    onChanged: (value) => _currentPassword = value,
                    validator: (value) {
                      if (_newPassword.isNotEmpty && value!.isEmpty) {
                        return 'Vui lòng nhập mật khẩu hiện tại để thay đổi';
                      }
                      return null;
                    },
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildTextFormField(
                    labelText: 'New Password (optional)',
                    obscureText: true,
                    onChanged: (value) => _newPassword = value,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 6) {
                        return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildTextFormField(
                    labelText: 'Confirm New Password',
                    obscureText: true,
                    onChanged: (value) => _confirmPassword = value,
                    validator: (value) {
                      if (_newPassword.isNotEmpty && value != _newPassword) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: Colors.pink.withOpacity(0.4),
                    ),
                    onPressed: _updateProfile,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.pinkAccent, Colors.deepOrangeAccent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        alignment: Alignment.center,
                        child: const Text(
                          "SAVE CHANGES",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
    ValueChanged<String>? onChanged,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    IconData? icon,
  }) {
    final Color accentColor = Colors.pinkAccent;
    final Color textColor = Colors.black.withOpacity(0.7);
    final Color labelColor = Colors.black54;
    final Color fillColor = Colors.white.withOpacity(0.4);
    final Color enabledBorderColor = Colors.grey.shade400;

    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onSaved: onSaved,
      validator: validator,
      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: labelColor),
        prefixIcon:
            icon != null
                ? Icon(icon, color: accentColor.withOpacity(0.8))
                : null,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 12.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: enabledBorderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: accentColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2.0),
        ),
        errorStyle: TextStyle(color: Colors.red.shade700),
      ),
    );
  }
}
