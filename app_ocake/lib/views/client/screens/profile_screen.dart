import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:app_ocake/services/database/session_manager.dart';
// -------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _imageFile;
  String?
  _networkAvatarUrl;
  bool _isLoadingData = true;
  bool _isUpdating = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {

    String? customerId =
        SessionManager.currentCustomerId; // Lấy ID từ SessionManager

    if (customerId == null) {
      print("ProfileScreen: No Customer ID in session. Cannot load profile.");
      if (mounted) {
        setState(() {
          _isLoadingData = false; // Dừng loading
        });
      }
      return;
    }

    print("ProfileScreen: Loading profile for Customer ID: $customerId");

    try {
      DocumentSnapshot customerDoc =
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(customerId)
              .get();

      if (customerDoc.exists && customerDoc.data() != null) {
        Map<String, dynamic> data = customerDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _nameController.text =
                data['name'] ?? SessionManager.currentCustomerName ?? '';
            _phoneController.text =
                data['phoneNumber'] ??
                SessionManager.currentCustomerPhone ??
                '';
            _addressController.text =
                data['address'] ?? SessionManager.currentCustomerAddress ?? '';
            _networkAvatarUrl = data['avatarUrl'] as String?;

            SessionManager.updateCurrentCustomerInfo(
              name: _nameController.text,
              phone: _phoneController.text,
              address: _addressController.text,
              avatarUrl: _networkAvatarUrl,
            );
            _isLoadingData = false;
          });
        }
      } else {
        print(
          "ProfileScreen: Customer document not found on Firestore for ID: $customerId",
        );
        // Có thể user đã bị xóa khỏi DB, xử lý logout
        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
          SessionManager.logout(context); // Gọi logout nếu user không tồn tại
        }
      }
    } catch (e) {
      print("Lỗi tải thông tin cá nhân: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin: ${e.toString()}')),
        );
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    // ... (Giữ nguyên hàm _pickImage từ code gốc của bạn)
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        // Khi chọn ảnh mới, ưu tiên hiển thị ảnh này, nên có thể xóa network image url hiển thị tạm
        // _networkAvatarUrl = null; // Hoặc để logic hiển thị trong CircleAvatar tự quyết định
      });
    }
  }


  Future<void> _updateProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    String? customerId = SessionManager.currentCustomerId;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy người dùng.')),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    String? newAvatarUrl;

    Map<String, dynamic> updatedData = {
      'name': _nameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .update(updatedData);
      SessionManager.updateCurrentCustomerInfo(
        name: updatedData['name'],
        phone: updatedData['phoneNumber'],
        address: updatedData['address'],
        // avatarUrl: newAvatarUrl ?? _networkAvatarUrl
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Color(0xFFBC132C),
          ),
        );
      }
    } catch (e) {
      print("Lỗi cập nhật thông tin: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _logout() {
    SessionManager.logout(
      context,
    ); // Hàm logout trong SessionManager sẽ tự điều hướng
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionManager.isLoggedIn() && !_isLoadingData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginScreen(),
            ), // Hoặc LoginScreenCustom
            (Route<dynamic> route) => false,
          );
        }
      });
      // Trả về một widget placeholder tạm thời trong khi điều hướng
      return Scaffold(
        appBar: AppBar(title: Text('Tài khoản')),
        body: Center(child: Text('Đang chuyển hướng...')),
      );
    }

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tài khoản', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFBC132C),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: _isUpdating ? null : _logout,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_networkAvatarUrl != null &&
                                            _networkAvatarUrl!.isNotEmpty
                                        ? NetworkImage(_networkAvatarUrl!)
                                        : const AssetImage(
                                          'assets/images/default_avatar.png',
                                        ) // Đảm bảo có ảnh này trong assets
                                        )
                                    as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUpdating ? null : _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFBC132C),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextFormFieldWithController(
                  controller: _nameController,
                  labelText: 'Họ và tên',
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Vui lòng nhập tên'
                              : null,
                  icon: Icons.person_outline,
                  readOnly: _isUpdating,
                ),
                const SizedBox(height: 18),
                _buildTextFormFieldWithController(
                  controller: _phoneController,
                  labelText: 'Số điện thoại',
                  keyboardType: TextInputType.phone,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Vui lòng nhập số điện thoại'
                              : null,
                  icon: Icons.phone_outlined,
                  readOnly:
                      _isUpdating, // Có thể muốn SĐT không cho sửa nếu nó là username
                ),
                const SizedBox(height: 18),
                _buildTextFormFieldWithController(
                  controller: _addressController,
                  labelText: 'Địa chỉ',
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Vui lòng nhập địa chỉ'
                              : null,
                  icon: Icons.home_outlined,
                  maxLines: 2,
                  readOnly: _isUpdating,
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFBC132C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 50,
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: _isUpdating ? null : _updateProfile,
                  child:
                      _isUpdating
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text(
                            'Lưu thay đổi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormFieldWithController({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    IconData? icon,
    bool readOnly = false,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Color(0xFFBC132C)),
        filled: true,
        fillColor:
            readOnly
                ? Colors.grey.shade200
                : Colors.grey.shade50, // Màu nền hơi khác một chút
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: readOnly ? Colors.transparent : Color(0xFFBC132C),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
    );
  }
}
