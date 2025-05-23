// lib/models/customer.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id; // Document ID (ví dụ: KH001)
  final String? address;
  final Timestamp? birthDate;
  final String name;
  final String password; // Lưu plaintext - KHÔNG AN TOÀN CHO PRODUCTION
  final String phoneNumber;
  final String? roleId;

  Customer({
    required this.id,
    this.address,
    this.birthDate,
    required this.name,
    required this.password,
    required this.phoneNumber,
    this.roleId,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return Customer(
      id: doc.id,
      address: data['address'] as String?,
      birthDate: data['birthDate'] as Timestamp?,
      name: data['name'] as String? ?? 'N/A',
      password: data['password'] as String? ?? '', // Đọc password plaintext
      phoneNumber: data['phoneNumber'] as String? ?? '',
      roleId: data['roleId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // Không cần lưu 'id' vì nó là document ID rồi
      if (address != null) 'address': address,
      if (birthDate != null) 'birthDate': birthDate,
      'name': name,
      'password': password,
      'phoneNumber': phoneNumber,
      if (roleId != null) 'roleId': roleId,
    };
  }
}
