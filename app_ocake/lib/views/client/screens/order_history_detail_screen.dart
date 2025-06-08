import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:app_ocake/models/order.dart'; // Đảm bảo OrderModel đã được cập nhật
import 'package:app_ocake/models/order_detail_item.dart'; // Đảm bảo OrderDetailItem đã được cập nhật

class OrderHistoryDetailScreen extends StatefulWidget {
  final String orderDocumentId; // Nhận Document ID của đơn hàng (ví dụ: DH001...)

  const OrderHistoryDetailScreen({Key? key, required this.orderDocumentId})
      : super(key: key);

  @override
  _OrderHistoryDetailScreenState createState() =>
      _OrderHistoryDetailScreenState();
}

class _OrderHistoryDetailScreenState extends State<OrderHistoryDetailScreen> {
  Future<OrderModel?>? _orderFuture; // Future để tải thông tin chính của đơn hàng

  @override
  void initState() {
    super.initState();
    _orderFuture = _loadOrderHeader(); // Bắt đầu tải thông tin đơn hàng
  }

  // Hàm tải thông tin chính của đơn hàng (bao gồm cả danh sách sản phẩm)
  Future<OrderModel?> _loadOrderHeader() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderDocumentId)
          .get();

      if (doc.exists) {
        // OrderModel.fromFirestore đã chịu trách nhiệm parse cả list items
        return OrderModel.fromFirestore(doc);
      } else {
        print('Không tìm thấy đơn hàng với ID: ${widget.orderDocumentId}');
        return null;
      }
    } catch (e) {
      print('Lỗi khi tải thông tin chi tiết đơn hàng: $e');
      // In StackTrace để debug dễ hơn
      // print(e.stackTrace); // Kích hoạt nếu muốn thấy call stack
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFBC132C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<OrderModel?>(
        future: _orderFuture,
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (orderSnapshot.hasError || !orderSnapshot.hasData || orderSnapshot.data == null) {
            // In lỗi chi tiết ra console nếu có
            if (orderSnapshot.hasError) {
              print("OrderHistoryDetailScreen Error: ${orderSnapshot.error}");
            }
            return const Center(child: Text('Lỗi tải thông tin đơn hàng. Vui lòng thử lại.'));
          }

          final order = orderSnapshot.data!;

          return SingleChildScrollView( // Bọc trong SingleChildScrollView để toàn bộ nội dung cuộn được
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin trạng thái đơn hàng và ngày đặt
                buildStatusOrder(order.id, order.status, order.orderDate),
                const Divider(),
                const SizedBox(height: 15),

                // Thông tin khách hàng
                const Text(
                  "Thông tin khách hàng:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Tên: ${order.customerName}'),
                _buildInfoRow(Icons.phone, 'SĐT: ${order.customerPhoneNumber}'), // Đảm bảo dùng customerPhone
                _buildInfoRow(
                  Icons.location_on,
                  'Địa chỉ: ${order.customerAddress}',
                ),
                if (order.notes != null && order.notes!.isNotEmpty)
                  _buildInfoRow(Icons.notes, 'Ghi chú: ${order.notes}'),
                const SizedBox(height: 15),

                // Danh sách sản phẩm trong đơn
                const Text(
                  "Các sản phẩm trong đơn:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                // TRUY CẬP TRỰC TIẾP order.items ĐÃ ĐƯỢC LOAD CÙNG OrderModel
                if (order.items.isEmpty)
                  const Center(
                    child: Text("Không có sản phẩm nào trong đơn hàng này."),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true, // Quan trọng: Để ListView không chiếm toàn bộ chiều cao còn lại
                    physics: const NeverScrollableScrollPhysics(), // Quan trọng: Để ListView không cuộn riêng
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      // Tính toán lineItemTotal nếu model chưa có
                      final double lineItemTotal = item.productPrice * item.productQuantity;
                      return buildDetailItem(
                        item.productImageUrl, // Sử dụng productImageUrl từ OrderDetailItem
                        item.productName, // Sử dụng name từ OrderDetailItem
                        '${item.productPrice.toStringAsFixed(0)}đ', // Đơn giá
                        item.productQuantity,
                        lineItemTotal, // Tổng tiền của dòng item này
                      );
                    },
                  ),
                const Divider(height: 25, thickness: 1), // Divider sau danh sách sản phẩm

                // Tổng tiền thanh toán
                ListTile(
                  title: const Text(
                    "Tổng tiền thanh toán",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  trailing: Text(
                    "${order.totalAmount.toStringAsFixed(0)}đ",
                    style: const TextStyle(
                      color: Color(0xFFBC132C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Nút "Đặt lại"
                TextButton(
                  onPressed: () {
                    // TODO: Logic đặt lại đơn hàng (ví dụ: thêm các sản phẩm vào giỏ hàng)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đặt lại đang phát triển.')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFBC132C),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Đặt lại",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget helper để tạo các dòng thông tin khách hàng
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  // Widget để hiển thị trạng thái và ngày đặt hàng
  Widget buildStatusOrder(
    String displayOrderId,
    String status,
    Timestamp orderDate, // Đổi tên createdAt thành orderDate cho rõ ràng
  ) {
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(orderDate.toDate());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mã ĐH: $displayOrderId",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == "Đã giao hàng"
                      ? Colors.green[100]
                      : (status.toLowerCase().contains("hủy")
                          ? Colors.red[100]
                          : Colors.orange[100]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status == "Đã giao hàng"
                        ? const Color(0xFFBC132C) // Màu chính (đỏ) cho "Đã giao hàng" có vẻ hơi lạ, thường là xanh
                        : (status.toLowerCase().contains("hủy")
                            ? Colors.red[800]
                            : Colors.orange[800]),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Ngày đặt: $formattedDate",
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // Widget để xây dựng từng dòng sản phẩm chi tiết trong đơn hàng
  Widget buildDetailItem(
    String imagePath,
    String title,
    String unitPrice,
    int quantity,
    double lineItemTotal,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset( // Sử dụng Image.asset vì bạn lưu đường dẫn asset
              imagePath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Đơn giá: $unitPrice",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                Text(
                  "Số lượng: $quantity",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${lineItemTotal.toStringAsFixed(0)}đ',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}