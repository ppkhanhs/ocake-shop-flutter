import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- SỬA LẠI ĐƯỜNG DẪN IMPORT CHO ĐÚNG VỚI DỰ ÁN CỦA BẠN ---
import 'login_screen.dart'; // Hoặc LoginScreenCustom
// Import SessionManager từ file riêng của nó
import 'package:app_ocake/services/database/session_manager.dart'; // Đảm bảo đường dẫn này đúng!
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

  File? _imageFile; // Ảnh mới được chọn từ gallery (cục bộ)
  String?
  _networkAvatarUrl; // URL ảnh từ Firestore (nếu có) - Giả sử có trường 'avatarUrl'
  bool _isLoadingData = true; // Trạng thái tải dữ liệu ban đầu
  bool _isUpdating = false; // Trạng thái đang cập nhật

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // Không cần setState(_isLoadingData = true) ở đây vì nó đã là true ban đầu

    String? customerId =
        SessionManager.currentCustomerId; // Lấy ID từ SessionManager

    if (customerId == null) {
      print("ProfileScreen: No Customer ID in session. Cannot load profile.");
      // Nếu không có customerId, có nghĩa là chưa đăng nhập, không cần tải gì cả.
      // Hàm build sẽ xử lý việc hiển thị UI "chưa đăng nhập".
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
            // Giả sử bạn có trường 'avatarUrl' trên Firestore để lưu link ảnh đại diện
            _networkAvatarUrl = data['avatarUrl'] as String?;

            // Cập nhật lại SessionManager nếu dữ liệu trên Firestore mới hơn (tùy chọn)
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

  // TODO: Hàm tải ảnh lên Firebase Storage (Bạn cần triển khai nếu muốn lưu ảnh online)
  // Future<String?> _uploadAvatarToStorage(File imageFile, String customerId) async {
  //   try {
  //     // Cần package firebase_storage
  //     // final storageRef = FirebaseStorage.instance.ref().child('customer_avatars/$customerId/${DateTime.now().millisecondsSinceEpoch}.jpg');
  //     // final uploadTask = storageRef.putFile(imageFile);
  //     // final snapshot = await uploadTask.whenComplete(() => {});
  //     // final downloadUrl = await snapshot.ref.getDownloadURL();
  //     // return downloadUrl;
  //     print("Logic upload ảnh chưa được triển khai");
  //     return null; // Trả về null nếu chưa có logic upload
  //   } catch (e) {
  //     print("Lỗi upload avatar: $e");
  //     return null;
  //   }
  // }

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
    // if (_imageFile != null) {
    //   // newAvatarUrl = await _uploadAvatarToStorage(_imageFile!, customerId);
    //   // if (newAvatarUrl == null && mounted) { // Lỗi upload ảnh
    //   //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh lên. Cập nhật thông tin không thành công.')));
    //   //   setState(() { _isUpdating = false; });
    //   //   return;
    //   // }
    // }

    Map<String, dynamic> updatedData = {
      'name': _nameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      // if (newAvatarUrl != null) 'avatarUrl': newAvatarUrl,
      // else if (_networkAvatarUrl != null && _imageFile == null) 'avatarUrl': _networkAvatarUrl, // Giữ ảnh cũ nếu không đổi
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
            backgroundColor: Colors.green,
          ),
        );
        // Nếu đã upload ảnh mới thành công, có thể reset _imageFile
        // setState(() { _imageFile = null; _networkAvatarUrl = newAvatarUrl ?? _networkAvatarUrl; });
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
    // Kiểm tra trạng thái đăng nhập ở đầu hàm build
    if (!SessionManager.isLoggedIn() && !_isLoadingData) {
      // Nếu không loading và cũng không đăng nhập, điều hướng về Login
      // Dùng addPostFrameCallback để tránh lỗi setState/navigation trong build
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

    // Nếu _isLoadingData là false và SessionManager.isLoggedIn() là true,
    // nhưng các controller vẫn rỗng (có thể xảy ra nếu _loadUserProfile chưa kịp set)
    // thì có thể vẫn hiển thị màn hình chính nhưng với các trường trống.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
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
                              color: Colors.green,
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
                    backgroundColor: Colors.green,
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
        prefixIcon: Icon(icon, color: Colors.green),
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
            color: readOnly ? Colors.transparent : Colors.green,
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
