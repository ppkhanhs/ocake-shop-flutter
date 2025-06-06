import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_detail_item.dart'; // Import model mới

class OrderModel {
  final String id; // Document ID của order (ví dụ: DH001)
  final String? customerId; // Có thể null nếu không có thông tin này
  final String customerName;
  final String customerAddress;
  final String customerPhoneNumber;
  final String? employeeId;
  final String? notes;
  final Timestamp orderDate;
  final String status;
  final double totalAmount;
  List<OrderDetailItem> items; // Danh sách chi tiết đơn hàng, sẽ được tải riêng

  OrderModel({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhoneNumber,
    this.employeeId,
    this.notes,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    this.items = const [], // Khởi tạo rỗng, sẽ được điền sau
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    Map<String, dynamic> customerInfo =
        data['customerInfo'] as Map<String, dynamic>? ?? {};

    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] as String?,
      customerName: customerInfo['name'] as String? ?? 'N/A',
      customerAddress: customerInfo['address'] as String? ?? 'N/A',
      customerPhoneNumber: customerInfo['phoneNumber'] as String? ?? 'N/A',
      employeeId: data['employeeId'] as String?,
      notes: data['notes'] as String?,
      orderDate: data['orderDate'] as Timestamp? ?? Timestamp.now(),
      status: data['status'] as String? ?? 'Không xác định',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      // items sẽ được tải riêng từ sub-collection
    );
  }
}
