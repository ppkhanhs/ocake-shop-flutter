import 'package:cloud_firestore/cloud_firestore.dart';

class Branch {
  final String id; // Document ID từ Firestore
  final String name;
  final String address;
  // final int? sortOrder; // Tùy chọn

  Branch({
    required this.id,
    required this.name,
    required this.address,
    // this.sortOrder,
  });

  factory Branch.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return Branch(
      id: doc.id,
      name: data['name'] as String? ?? 'Tên chi nhánh không xác định',
      address: data['address'] as String? ?? 'Địa chỉ không xác định',
      // sortOrder: data['sortOrder'] as int?,
    );
  }

  Map<String, String> toMapForDropdown() {
    return {
      'name': name,
      'address': address,
      // Quan trọng: thêm 'id' vào đây nếu bạn muốn dùng ID để xác định value của Dropdown
      // Hoặc bạn có thể dùng 'address' làm value như hiện tại
      // 'id': id,
    };
  }
}
