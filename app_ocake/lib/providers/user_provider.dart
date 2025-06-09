// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_ocake/models/customer.dart'; // Giả sử đây là model Customer của bạn

class UserProvider with ChangeNotifier {
  Customer? _currentUser; // Thông tin chi tiết của người dùng/khách hàng
  String? _userId; // ID của người dùng (từ Firebase Auth hoặc customerId)
  bool _isLoadingProfile = false;
  bool _isUpdatingProfile = false;

  Customer? get currentUser => _currentUser;
  String? get userId => _userId;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isUpdatingProfile => _isUpdatingProfile;

  UserProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _userId = user.uid;
        loadUserProfile(user.uid); // Tải profile khi user đăng nhập
      } else {
        _userId = null;
        _currentUser = null;
        notifyListeners(); // Thông báo cho UI biết không còn user
      }
    });
  }

  // Hàm này sẽ được Màn hình Login gọi sau khi đăng nhập tùy chỉnh thành công
  Future<void> loginCustomUser(String customerId) async {
    _userId = customerId;
    if (_userId == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }
    await loadUserProfile(customerId);
    // Không cần notifyListeners() ở đây vì loadUserProfile đã làm
  }

  Future<void> loadUserProfile(String userIdToLoad) async {
    if (userIdToLoad.isEmpty) {
      _currentUser = null;
      _isLoadingProfile = false;
      notifyListeners();
      return;
    }

    _isLoadingProfile = true;
    notifyListeners();

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('customers') // Collection customer của bạn
              .doc(userIdToLoad)
              .get();

      if (doc.exists && doc.data() != null) {
        _currentUser = Customer.fromFirestore(
          doc,
        ); // Sử dụng model Customer của bạn
      } else {
        _currentUser = null; // Không tìm thấy user
        print("UserProvider: Không tìm thấy customer với ID: $userIdToLoad");
      }
    } catch (e) {
      _currentUser = null;
      print("UserProvider: Lỗi tải user profile: $e");
      // Có thể thêm biến _error message ở đây để UI hiển thị
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile({
    required String customerId, // Dùng customerId để biết update document nào
    required String name,
    required String phone,
    required String address,
    
  }) async {
    _isUpdatingProfile = true;
    notifyListeners();

    Map<String, dynamic> dataToUpdate = {
      'name': name,
      'phoneNumber': phone, // Khớp tên trường trên Firestore
      'address': address,
    };

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .update(dataToUpdate);

      // Sau khi update thành công, cập nhật lại _currentUser
      // Cách đơn giản là tạo lại customer object, hoặc gọi lại loadUserProfile
      _currentUser = Customer(
        id: customerId,
        name: name,
        phoneNumber: phone,
        address: address,
        password:
            _currentUser?.password ??
            '', // Giữ lại password cũ (không nên cập nhật password ở đây)
        birthDate: _currentUser?.birthDate,
        roleId: _currentUser?.roleId,
        // avatarUrl: newAvatarUrl ?? _currentUser?.avatarUrl,
      );

      _isUpdatingProfile = false;
      notifyListeners();
      return true; // Cập nhật thành công
    } catch (e) {
      print("UserProvider: Lỗi cập nhật profile: $e");
      _isUpdatingProfile = false;
      notifyListeners();
      return false; // Cập nhật thất bại
    }
  }

  // (Tùy chọn) Hàm upload avatar
  // Future<String?> _uploadAvatar(File imageFile, String customerId) async { ... }

  void logout() {
    // Nếu bạn dùng Firebase Auth, gọi FirebaseAuth.instance.signOut();
    // Nếu là hệ thống tùy chỉnh, chỉ cần reset state
    _userId = null;
    _currentUser = null;
    // TODO: Có thể cần xóa token/session lưu cục bộ nếu có
    print("UserProvider: User logged out.");
    notifyListeners();
  }
}
