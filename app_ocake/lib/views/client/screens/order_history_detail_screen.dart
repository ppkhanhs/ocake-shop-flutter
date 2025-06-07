import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:app_ocake/models/order.dart'; // Model OrderModel đã cập nhật
import 'package:app_ocake/models/order_detail_item.dart'; // Model OrderDetailItem mới

class OrderHistoryDetailScreen extends StatefulWidget {
  final String orderDocumentId; // Nhận Document ID của đơn hàng (ví dụ: DH001)

  const OrderHistoryDetailScreen({Key? key, required this.orderDocumentId})
    : super(key: key);

  @override
  _OrderHistoryDetailScreenState createState() =>
      _OrderHistoryDetailScreenState();
}

class _OrderHistoryDetailScreenState extends State<OrderHistoryDetailScreen> {
  Future<OrderModel?>? _orderFuture;
  // Future để tải danh sách chi tiết sản phẩm
  Future<List<OrderDetailItem>>? _orderDetailsFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _loadOrderHeader(); // Tải thông tin chính của đơn hàng
  }

  Future<OrderModel?> _loadOrderHeader() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderDocumentId)
              .get();

      if (doc.exists) {
        OrderModel order = OrderModel.fromFirestore(doc);
        // Sau khi có thông tin order, bắt đầu tải orderDetails
        _orderDetailsFuture = _loadOrderDetails(
          order.id,
        ); // Dùng order.id (document ID)
        return order;
      } else {
        print('Không tìm thấy đơn hàng với ID: ${widget.orderDocumentId}');
        return null;
      }
    } catch (e) {
      print('Lỗi khi tải thông tin chính của đơn hàng: $e');
      return null;
    }
  }

  Future<List<OrderDetailItem>> _loadOrderDetails(String orderDocId) async {
    try {
      QuerySnapshot orderDetailsSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderDocId) // Document ID của đơn hàng cha
              .collection('orderDetails') // Sub-collection
              .get();

      return orderDetailsSnapshot.docs
          .map((doc) => OrderDetailItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Lỗi khi tải chi tiết sản phẩm của đơn hàng: $e');
      return []; // Trả về list rỗng nếu lỗi
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
        backgroundColor: Color(0xFFBC132C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<OrderModel?>(
        future: _orderFuture,
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (orderSnapshot.hasError ||
              !orderSnapshot.hasData ||
              orderSnapshot.data == null) {
            return Center(child: Text('Lỗi tải thông tin đơn hàng.'));
          }

          final order = orderSnapshot.data!;

          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Sử dụng order.id nếu bạn muốn hiển thị Document ID (DH001)
                // Hoặc nếu orderId trong data khác với doc.id, dùng order.orderId
                buildStatusOrder(order.id, order.status, order.orderDate),
                Divider(),
                SizedBox(height: 15),
                Text(
                  "Thông tin khách hàng:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Tên: ${order.customerName}'),
                _buildInfoRow(Icons.phone, 'SĐT: ${order.customerPhoneNumber}'),
                _buildInfoRow(
                  Icons.location_on,
                  'Địa chỉ: ${order.customerAddress}',
                ),
                if (order.notes != null && order.notes!.isNotEmpty)
                  _buildInfoRow(Icons.notes, 'Ghi chú: ${order.notes}'),
                SizedBox(height: 15),
                Text(
                  "Các sản phẩm trong đơn:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  // FutureBuilder thứ hai để tải và hiển thị orderDetails
                  child: FutureBuilder<List<OrderDetailItem>>(
                    future: _orderDetailsFuture,
                    builder: (context, detailsSnapshot) {
                      if (detailsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (detailsSnapshot.hasError ||
                          !detailsSnapshot.hasData ||
                          detailsSnapshot.data == null) {
                        return Center(
                          child: Text('Lỗi tải danh sách sản phẩm.'),
                        );
                      }
                      if (detailsSnapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            "Không có sản phẩm nào trong đơn hàng này.",
                          ),
                        );
                      }

                      final orderItems = detailsSnapshot.data!;
                      return ListView.builder(
                        itemCount: orderItems.length,
                        itemBuilder: (context, index) {
                          final item = orderItems[index];
                          return buildDetailItem(
                            item.productImageUrl, // Sử dụng image URL từ OrderDetailItem
                            item.productName,
                            '${item.productPrice.toStringAsFixed(0)}đ',
                            item.productQuantity,
                            item.lineItemTotal, // Truyền lineItemTotal để hiển thị
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
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
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    /* TODO: Logic đặt lại */
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Color(0xFFBC132C),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 18),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget buildStatusOrder(
    String displayOrderId,
    String status,
    Timestamp createdAt,
  ) {
    String formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(createdAt.toDate());
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      status == "Đã giao hàng"
                          ? Colors.green[100]
                          : (status.toLowerCase().contains("hủy")
                              ? Colors.red[100]
                              : Colors.orange[100]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color:
                        status == "Đã giao hàng"
                            ? Color(0xFFBC132C)
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
          SizedBox(height: 4),
          Text(
            "Ngày đặt: $formattedDate",
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

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
            child: Image.asset(
              imagePath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder:
                  (c, e, s) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported),
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
                SizedBox(height: 4),
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
            '${lineItemTotal.toStringAsFixed(0)}đ', // Hiển thị tổng tiền của dòng item này
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
