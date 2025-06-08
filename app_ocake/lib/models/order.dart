import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_ocake/models/order_detail_item.dart'; // Đảm bảo import đúng đường dẫn

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhoneNumber;
  final String customerAddress;
  final String paymentMethod;
  final double totalAmount;
  final List<OrderDetailItem> items;
  final String status;
  final Timestamp orderDate; // Sử dụng Timestamp trực tiếp cho đồng bộ với Firestore
  final String? employeeId; // Có thể null
  final String? notes; // Có thể null

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhoneNumber,
    required this.customerAddress,
    required this.paymentMethod,
    required this.totalAmount,
    required this.items,
    required this.status,
    required this.orderDate,
    this.employeeId,
    this.notes,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError('Order document data is null for ID: ${doc.id}');
    }

    // Đảm bảo an toàn khi đọc dữ liệu, cung cấp giá trị mặc định hoặc throw lỗi rõ ràng
    final String id = doc.id;
    
    // Lấy thông tin khách hàng từ nested map 'customerInfo'
    final Map<String, dynamic>? customerInfo = data['customerInfo'] as Map<String, dynamic>?;

    final String customerId = data['customerId'] as String? ?? ''; // Giả định customerId có thể null trong trường hợp đặc biệt
    final String customerName = customerInfo?['name'] as String? ?? 'N/A'; // Lấy từ customerInfo
    final String customerPhone = customerInfo?['phone'] as String? ?? 'N/A'; // Lấy từ customerInfo
    final String customerAddress = customerInfo?['address'] as String? ?? 'N/A'; // Lấy từ customerInfo
    
    final String paymentMethod = data['paymentMethod'] as String? ?? 'N/A';
    final double totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final String status = data['status'] as String? ?? 'Unknown';
    final Timestamp orderDate = data['orderDate'] as Timestamp? ?? Timestamp.now(); // Cung cấp giá trị mặc định an toàn

    // Parse items list
    final List<dynamic>? itemsData = data['items'] as List<dynamic>?;
    final List<OrderDetailItem> items = (itemsData ?? [])
        .map((itemMap) => OrderDetailItem.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    final String? employeeId = data['employeeId'] as String?; // Optional
    final String? notes = data['notes'] as String?; // Optional

    return OrderModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerPhoneNumber: customerPhone,
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      items: items,
      status: status,
      orderDate: orderDate,
      employeeId: employeeId,
      notes: notes,
    );
  }
}