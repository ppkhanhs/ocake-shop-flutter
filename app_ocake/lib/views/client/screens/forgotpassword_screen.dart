import 'package:flutter/material.dart';
// Import LoginScreen nếu bạn muốn điều hướng cụ thể
// import 'login_screen.dart'; // Hoặc LoginScreenCustom

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // Thêm GlobalKey cho Form
  final phoneController = TextEditingController();
  bool _isLoading = false; // Để xử lý trạng thái loading cho nút

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    FocusScope.of(context).unfocus(); // Ẩn bàn phím
    if (!_formKey.currentState!.validate()) {
      // Validate form
      return;
    }

    final phone = phoneController.text.trim();
    setState(() {
      _isLoading = true;
    });

    // --- LOGIC GỬI OTP GIẢ LẬP ---
    // Trong thực tế, bạn sẽ gọi API hoặc Firebase Auth ở đây
    print("Yêu cầu gửi OTP đến số điện thoại: $phone");

    // Giả lập thời gian chờ gửi OTP
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Kiểm tra widget còn tồn tại
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Mã OTP (giả lập) đã được gửi đến số điện thoại của bạn.",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
    // -----------------------------
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24.0,
            12.0,
            24.0,
            24.0,
          ), // Điều chỉnh padding top
          child: SingleChildScrollView(
            child: Form(
              // Bọc trong Form widget
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black54,
                      ), // Icon rõ hơn
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo_hylammon.png',
                          height: 70,
                        ), // Giảm chiều cao logo một chút
                        const SizedBox(height: 20), // Tăng khoảng cách
                        const Text(
                          "Quên mật khẩu",
                          style: TextStyle(
                            fontSize: 26, // Giảm fontSize một chút
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBC132C),
                          ),
                        ),
                        const SizedBox(height: 10), // Tăng khoảng cách
                        const Text(
                          "Nhập số điện thoại đã đăng ký để chúng tôi gửi mã OTP đặt lại mật khẩu.", // Sửa lại mô tả
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ), // Giảm fontSize
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    // Đổi thành TextFormField để validate
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Colors.grey,
                      ),
                      hintText: "Số điện thoại",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        // Thêm viền khi focus
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFBC132C).withOpacity(0.7),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        // Viền nhẹ khi enabled
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số điện thoại.';
                      }
                      // (Tùy chọn) Thêm validation regex cho SĐT Việt Nam
                      // if (!RegExp(r"^(0[3|5|7|8|9])+([0-9]{8})\b").hasMatch(value)) {
                      //   return 'Số điện thoại không hợp lệ.';
                      // }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30), // Tăng khoảng cách
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // Đổi sang ElevatedButton
                      onPressed: _isLoading ? null : _sendResetLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFBC132C), // Màu nền
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
                                "Lấy mã OTP",
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
                        const Text("Bạn đã nhớ mật khẩu?"),
                        TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    Navigator.pop(
                                      context,
                                    ); // Quay lại màn hình đăng nhập
                                  },
                          child: const Text(
                            "Đăng nhập ngay", // Sửa lại text một chút
                            style: TextStyle(
                              color: Color(0xFFBC132C),
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
