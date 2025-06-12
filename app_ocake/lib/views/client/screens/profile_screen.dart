import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'login_screen.dart';
import 'package:app_ocake/services/database/session_manager.dart';
import 'package:app_ocake/views/client/screens/order_history_screen.dart'; // Import OrderHistoryScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // GlobalKey cho Form (nếu có form chung, nhưng giờ dùng cho dialog)
  // final _formKey = GlobalKey<FormState>(); // Có thể bỏ nếu không dùng form chung
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _imageFile;
  String? _networkAvatarUrl; // URL ảnh từ Firestore (nếu có)
  bool _isLoadingData = true; // Trạng thái tải dữ liệu ban đầu
  bool _isUpdating = false; // Trạng thái đang cập nhật (chung cho mọi thao tác update)

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance của Firebase Auth

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    String? customerId = SessionManager.currentCustomerId;

    if (customerId == null) {
      print("ProfileScreen: No Customer ID in session. Cannot load profile.");
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
      return;
    }

    print("ProfileScreen: Loading profile for Customer ID: $customerId");

    try {
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();

      if (customerDoc.exists && customerDoc.data() != null) {
        Map<String, dynamic> data = customerDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _nameController.text = data['name'] ?? SessionManager.currentCustomerName ?? '';
            _phoneController.text = data['phoneNumber'] ?? SessionManager.currentCustomerPhone ?? '';
            _addressController.text = data['address'] ?? SessionManager.currentCustomerAddress ?? '';
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
        print("ProfileScreen: Customer document not found on Firestore for ID: $customerId");
        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
          SessionManager.logout(context);
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

  // Hàm chọn ảnh (giữ nguyên)
  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        // TODO: Implement image upload to Firebase Storage if needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chọn ảnh mới. Vui lòng lưu để cập nhật.')),
        );
      });
    }
  }

  // Hàm cập nhật profile (ảnh đại diện và tên)
  Future<void> _updateProfile({String? nameToUpdate}) async {
    FocusScope.of(context).unfocus(); // Ẩn bàn phím

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

    // TODO: Triển khai upload ảnh lên Firebase Storage nếu _imageFile != null
    // String? newAvatarUrl;
    // if (_imageFile != null) {
    //   newAvatarUrl = await _uploadAvatarToStorage(_imageFile!, customerId);
    //   if (newAvatarUrl == null) {
    //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh lên.')));
    //     if(mounted) setState(() { _isUpdating = false; });
    //     return;
    //   }
    // }

    Map<String, dynamic> updatedData = {
      if (nameToUpdate != null) 'name': nameToUpdate, // Chỉ cập nhật tên nếu được truyền vào
      // if (newAvatarUrl != null) 'avatarUrl': newAvatarUrl, // Thêm nếu có upload ảnh
    };

    try {
      await FirebaseFirestore.instance.collection('customers').doc(customerId).update(updatedData);
      SessionManager.updateCurrentCustomerInfo(
        name: nameToUpdate ?? SessionManager.currentCustomerName,
        // avatarUrl: newAvatarUrl ?? _networkAvatarUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: Color(0xFFBC132C),
          ),
        );
        // Sau khi cập nhật thành công, nếu có ảnh mới, cập nhật lại _networkAvatarUrl và xóa _imageFile tạm
        // if(newAvatarUrl != null) setState(() { _networkAvatarUrl = newAvatarUrl; _imageFile = null; });
        if(nameToUpdate != null) setState(() { _nameController.text = nameToUpdate; });
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

  // Hàm cập nhật địa chỉ
  Future<void> _updateAddress({required String newAddress, required String newPhone}) async {
    FocusScope.of(context).unfocus();

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

    Map<String, dynamic> updatedData = {
      'address': newAddress.trim(),
      'phoneNumber': newPhone.trim(), // Cập nhật số điện thoại ở đây nếu cần
    };

    try {
      await FirebaseFirestore.instance.collection('customers').doc(customerId).update(updatedData);
      SessionManager.updateCurrentCustomerInfo(
        address: newAddress,
        phone: newPhone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật địa chỉ thành công!'),
            backgroundColor: Color(0xFFBC132C),
          ),
        );
        setState(() {
          _addressController.text = newAddress;
          _phoneController.text = newPhone;
        });
      }
    } catch (e) {
      print("Lỗi cập nhật địa chỉ: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật địa chỉ thất bại: ${e.toString()}')),
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

  // Hàm đổi mật khẩu (Sử dụng Firebase Authentication)
  Future<void> _changePassword(String oldPassword, String newPassword) async {
    FocusScope.of(context).unfocus();

    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa đăng nhập hoặc phiên hết hạn.')),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // Re-authenticate user with old password
      AuthCredential credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!, // Giả định email là phương thức đăng nhập
        password: oldPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await _auth.currentUser!.updatePassword(newPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu đã được đổi thành công!'),
            backgroundColor: Color(0xFFBC132C),
          ),
        );
        // Có thể yêu cầu người dùng đăng nhập lại nếu muốn an toàn hơn
        // SessionManager.logout(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'wrong-password') {
        errorMessage = 'Mật khẩu cũ không đúng.';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng xuất và đăng nhập lại để đổi mật khẩu.';
      } else {
        errorMessage = 'Lỗi đổi mật khẩu: ${e.message}';
      }
      print("Lỗi đổi mật khẩu Firebase: ${e.code} - ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print("Lỗi đổi mật khẩu chung: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đổi mật khẩu: ${e.toString()}')),
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
    SessionManager.logout(context);
  }

  // Helper widget để xây dựng các dòng thông tin (để xem, không sửa trực tiếp)
  Widget _buildInfoRow({required IconData icon, required String title, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionManager.isLoggedIn() && !_isLoadingData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      });
      return Scaffold(appBar: AppBar(title: const Text('Tài khoản')), body: const Center(child: Text('Đang chuyển hướng...')));
    }

    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tài khoản', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền tổng thể
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Phần Header Profile (Màu xanh)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50.0, bottom: 20.0), // Padding trên và dưới
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFBC132C), Color(0xFFBC132C)], // Gradient xanh
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)), // Bo góc dưới
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50, // Kích thước avatar
                        backgroundColor: Colors.white,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_networkAvatarUrl != null && _networkAvatarUrl!.isNotEmpty
                                ? NetworkImage(_networkAvatarUrl!)
                                : const AssetImage('assets/images/avatar_default.jpg')) as ImageProvider,
                      ),
                      // Nút đổi ảnh (có thể xóa nếu chỉ cho đổi trong dialog)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUpdating ? null : _pickImage, // Cho phép chọn ảnh mới
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt, color: Color(0xFF689F38), size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'Người dùng',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _phoneController.text.isNotEmpty ? _phoneController.text : 'Chưa có SĐT',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Các mục hành động nhanh (Đơn hàng của tôi, Đã xem gần đây, Kho Voucher)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.assignment,
                    label: 'Đơn hàng của tôi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderHistoryScreen()), // Điều hướng đến OrderHistoryScreen
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.access_time,
                    label: 'Đã xem gần đây',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chức năng "Đã xem gần đây" đang phát triển.')),
                      );
                    },
                  ),
                  _buildQuickActionButton(
                    icon: Icons.card_giftcard,
                    label: 'Kho Voucher',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chức năng "Kho Voucher" đang phát triển.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section "Tài khoản"
            _buildSectionHeader('Tài khoản'),
            _buildInfoCard([
              _buildInfoRow(
                icon: Icons.person_outline,
                title: 'Thông tin cá nhân',
                onTap: () => _showEditProfileDialog(context), // Mở dialog chỉnh sửa thông tin cá nhân
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildInfoRow(
                icon: Icons.location_on_outlined,
                title: 'Địa chỉ nhận hàng',
                onTap: () => _showEditAddressDialog(context), // Mở dialog chỉnh sửa địa chỉ
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildInfoRow(
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                onTap: () => _showChangePasswordDialog(context), // Mở dialog đổi mật khẩu
              ),
            ]),
            const SizedBox(height: 20),

            // Section "Khác"
            _buildSectionHeader('Khác'),
            _buildInfoCard([
              _buildInfoRow(
                icon: Icons.description_outlined,
                title: 'Chính sách Hỷ Lâm Môn ',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xem Chính sách Hỷ Lâm Môn')),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildInfoRow(
                icon: Icons.help_outline,
                title: 'Trung tâm trợ giúp',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đến Trung tâm trợ giúp')),
                  );
                },
              ),
            ]),
            const SizedBox(height: 30),

            // Nút Đăng xuất
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBC132C),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Đăng xuất',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Helper widget cho các nút hành động nhanh (Đơn hàng, Đã xem, Voucher)
  Widget _buildQuickActionButton({required IconData icon, required String label, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              Icon(icon, size: 35, color: const Color(0xFF689F38)), // Màu xanh icon
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget cho tiêu đề section (Tài khoản, Khác)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 10.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // Helper widget cho các Card chứa danh sách tùy chọn (Thông tin, Địa chỉ, Đổi mật khẩu)
  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        children: children,
      ),
    );
  }

  // Helper widget để xây dựng TextFormField trong dialog
  Widget _buildDialogTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    bool obscureText = false,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[700]),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF689F38), width: 1.5),
        ),
      ),
    );
  }

  // NEW: Dialog chỉnh sửa thông tin cá nhân (tên, ảnh đại diện)
  Future<void> _showEditProfileDialog(BuildContext context) async {
    TextEditingController tempNameController = TextEditingController(text: _nameController.text);
    // Bạn có thể thêm logic cho ảnh đại diện ở đây nếu muốn chỉnh sửa trong dialog
    // final File? tempImageFile = _imageFile;

    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin cá nhân'),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextFormField(
                    controller: tempNameController,
                    labelText: 'Họ và tên',
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              child: const Text('Lưu'),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  _updateProfile(nameToUpdate: tempNameController.text);
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // NEW: Dialog chỉnh sửa địa chỉ nhận hàng
  Future<void> _showEditAddressDialog(BuildContext context) async {
    TextEditingController tempPhoneController = TextEditingController(text: _phoneController.text);
    TextEditingController tempAddressController = TextEditingController(text: _addressController.text);
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa địa chỉ nhận hàng'),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextFormField(
                    controller: tempPhoneController,
                    labelText: 'Số điện thoại',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại.';
                      if (!RegExp(r'^0\d{9,11}$').hasMatch(value)) return 'SĐT không hợp lệ (10-12 số, bắt đầu bằng 0).';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextFormField(
                    controller: tempAddressController,
                    labelText: 'Địa chỉ nhận hàng',
                    maxLines: 3,
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              child: const Text('Lưu'),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  _updateAddress(
                    newAddress: tempAddressController.text,
                    newPhone: tempPhoneController.text,
                  );
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // NEW: Dialog đổi mật khẩu
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmNewPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextFormField(
                    controller: oldPasswordController,
                    labelText: 'Mật khẩu cũ',
                    obscureText: true,
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu cũ.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextFormField(
                    controller: newPasswordController,
                    labelText: 'Mật khẩu mới',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới.';
                      if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextFormField(
                    controller: confirmNewPasswordController,
                    labelText: 'Xác nhận mật khẩu mới',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu mới.';
                      if (value != newPasswordController.text) return 'Mật khẩu xác nhận không khớp.';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Lưu'),
              onPressed: _isUpdating
                  ? null
                  : () {
                      if (dialogFormKey.currentState!.validate()) {
                        _changePassword(oldPasswordController.text, newPasswordController.text);
                        Navigator.pop(dialogContext); // Đóng dialog sau khi gọi hàm đổi mật khẩu
                      }
                    },
            ),
          ],
        );
      },
    );
  }
}