import 'package:flutter/material.dart';
import 'package:app_ocake/views/client/screens/login_screen.dart'; // Hoặc LoginScreenCustom

class SessionManager {
  static String? currentCustomerId;
  static String? currentCustomerName;
  // --- THÊM CÁC BIẾN STATIC NÀY ---
  static String? currentCustomerPhone;
  static String? currentCustomerAddress;
  static String? currentCustomerAvatarUrl; // Nếu bạn dùng
  // ----------------------------------

  static void login(
    String customerId,
    String customerName, {
    String? phone,
    String? address,
    String? avatarUrl,
  }) {
    currentCustomerId = customerId;
    currentCustomerName = customerName;
    // --- GÁN GIÁ TRỊ KHI LOGIN ---
    currentCustomerPhone = phone;
    currentCustomerAddress = address;
    currentCustomerAvatarUrl = avatarUrl;
    // -----------------------------
    print(
      "SessionManager: Logged in user $currentCustomerName (ID: $currentCustomerId, Phone: $currentCustomerPhone)",
    );
  }

  static void logout(BuildContext context) {
    currentCustomerId = null;
    currentCustomerName = null;
    // --- RESET KHI LOGOUT ---
    currentCustomerPhone = null;
    currentCustomerAddress = null;
    currentCustomerAvatarUrl = null;
    // ------------------------
    print("SessionManager: User logged out.");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  static bool isLoggedIn() {
    return currentCustomerId != null;
  }

  // Hàm để cập nhật thông tin session nếu user sửa profile
  static void updateCurrentCustomerInfo({
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) {
    if (name != null) currentCustomerName = name;
    // --- CẬP NHẬT CÁC TRƯỜNG MỚI ---
    if (phone != null) currentCustomerPhone = phone;
    if (address != null) currentCustomerAddress = address;
    if (avatarUrl != null) currentCustomerAvatarUrl = avatarUrl;
    // ---------------------------------
    print(
      "SessionManager: Updated local info - Name: $currentCustomerName, Phone: $currentCustomerPhone, Address: $currentCustomerAddress",
    );
  }
}
