import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
// Import LoginScreen nếu bạn muốn đảm bảo Navigator.pop(context) hoạt động đúng
// import 'login_screen.dart'; // Hoặc tên file login_screen_custom.dart của bạn

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // Thêm GlobalKey cho Form
  final usernameController =
      TextEditingController(); // Đổi tên thành nameController cho nhất quán
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  // (Tùy chọn) Thêm các controller khác nếu bạn muốn nhập thêm thông tin khi đăng ký
  // final addressController = TextEditingController();
  // DateTime? _selectedBirthDate;

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool _isLoading = false; // Thêm biến trạng thái loading

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    // addressController.dispose(); // Dispose nếu bạn thêm
    super.dispose();
  }

  // --- HÀM XỬ LÝ ĐĂNG KÝ VỚI FIRESTORE ---
  Future<void> _registerWithFirestore() async {
    // Validate form trước
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Kiểm tra mật khẩu khớp nhau đã có trong validator của confirmPasswordController

    setState(() {
      _isLoading = true;
    });

    final name =
        usernameController.text.trim(); // Lấy tên từ usernameController
    final phone = phoneController.text.trim();
    final password = passwordController.text; // Sẽ lưu plaintext
    // final address = addressController.text.trim(); // Nếu có

    try {
      // 1. Kiểm tra xem số điện thoại đã tồn tại chưa
      final existingUserQuery =
          await FirebaseFirestore.instance
              .collection('customers') // Tên collection khách hàng của bạn
              .where('phoneNumber', isEqualTo: phone)
              .limit(1)
              .get();

      if (existingUserQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Số điện thoại này đã được đăng ký.'),
            backgroundColor: Colors.orange,
          ),
        );
        if (mounted)
          setState(() {
            _isLoading = false;
          });
        return;
      }

      // 2. Tạo Document ID mới cho customer (Firestore sẽ tự tạo nếu bạn dùng .add())
      // Hoặc bạn có thể tạo ID tùy chỉnh nếu muốn (ví dụ: "KH" + timestamp)
      // Sử dụng .add() để Firestore tự tạo ID:
      DocumentReference
      newCustomerRef = await FirebaseFirestore.instance.collection('customers').add({
        'name': name,
        'phoneNumber': phone,
        'password': password, // LƯU PLAINTEXT - KHÔNG AN TOÀN CHO PRODUCTION
        'roleId': 'customer', // Giá trị mặc định cho role
        'createdAt': FieldValue.serverTimestamp(), // Thời gian tạo tài khoản
        // 'address': address, // Nếu có
        // 'birthDate': _selectedBirthDate != null ? Timestamp.fromDate(_selectedBirthDate!) : null, // Nếu có
        // Khởi tạo sub-collection cartItems rỗng (tùy chọn)
        // Không nhất thiết phải làm ở đây, nó sẽ tự tạo khi item đầu tiên được thêm
      });

      print('Đăng ký thành công cho user: $name, ID: ${newCustomerRef.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đăng ký thành công! Vui lòng đăng nhập."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // Đợi SnackBar hiển thị xong rồi mới pop
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context); // Quay lại trang đăng nhập
        }
      });
    } catch (e) {
      print("Lỗi đăng ký Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng ký thất bại: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            // Bọc nội dung trong Form
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                      ), // Đổi thành arrow_back cho nhất quán
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  // ... (Phần logo và tiêu đề giữ nguyên) ...
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_hylammon.png',
                          height: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Đăng ký",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Chào mừng bạn đến với Hỷ Lâm Môn",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30), // Giảm chút so với 40

                  TextFormField(
                    // Đổi TextField thành TextFormField để dùng với Form
                    controller: usernameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      hintText: "Họ và tên",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Vui lòng nhập họ và tên.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_outlined),
                      hintText: "Số điện thoại",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Vui lòng nhập số điện thoại.';
                      // (Tùy chọn) Thêm validation regex cho SĐT Việt Nam
                      // if (!RegExp(r"^(0[3|5|7|8|9])+([0-9]{8})\b").hasMatch(value)) return 'Số điện thoại không hợp lệ.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: "Mật khẩu",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Vui lòng nhập mật khẩu.';
                      if (value.length < 6)
                        return 'Mật khẩu phải có ít nhất 6 ký tự.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_person_outlined,
                      ), // Icon khác một chút
                      hintText: "Nhập lại mật khẩu",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible =
                                !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Vui lòng nhập lại mật khẩu.';
                      if (value != passwordController.text)
                        return 'Mật khẩu xác nhận không khớp.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // Đổi sang ElevatedButton
                      onPressed:
                          _isLoading
                              ? null
                              : _registerWithFirestore, // Gọi hàm đăng ký mới
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Màu nền
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                              : const Text(
                                "Đăng ký",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Bạn đã có tài khoản rồi hả?"),
                        TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    Navigator.pop(context);
                                  },
                          child: const Text(
                            "Đăng nhập",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
}
