import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:app_ocake/models/order.dart'; 
import 'package:app_ocake/models/order_detail_item.dart';

class OrderHistoryDetailScreen extends StatefulWidget {
  final String orderDocumentId;

  const OrderHistoryDetailScreen({Key? key, required this.orderDocumentId})
      : super(key: key);

  @override
  _OrderHistoryDetailScreenState createState() =>
      _OrderHistoryDetailScreenState();
}

class _OrderHistoryDetailScreenState extends State<OrderHistoryDetailScreen> {
  Future<OrderModel?>? _orderFuture; // Future để tải thông tin chính của đơn hàng
  bool _isCancelling = false; // Biến trạng thái khi đang hủy đơn hàng

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
        return OrderModel.fromFirestore(doc);
      } else {
        print('Không tìm thấy đơn hàng với ID: ${widget.orderDocumentId}');
        return null;
      }
    } catch (e) {
      print('Lỗi khi tải thông tin chi tiết đơn hàng: $e');
      return null;
    }
  }

  Future<void> _confirmCancelOrder(String orderId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Người dùng phải nhấn nút để đóng
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận hủy đơn hàng'),
          content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không? Hành động này không thể hoàn tác.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Không'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Có, Hủy đơn'),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isCancelling = true;
      });
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'status': 'Đã hủy', // Cập nhật trạng thái thành 'Đã hủy'
          'cancelledAt': FieldValue.serverTimestamp(), // Tùy chọn: Thêm thời gian hủy
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đơn hàng đã được hủy thành công!'), backgroundColor: Colors.green),
          );
          // Tải lại thông tin đơn hàng để UI hiển thị trạng thái mới
          setState(() {
            _orderFuture = _loadOrderHeader(); // Re-fetch data
          });
        }
      } catch (e) {
        print("Lỗi khi hủy đơn hàng: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hủy đơn hàng thất bại: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCancelling = false;
          });
        }
      }
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
            if (orderSnapshot.hasError) {
              print("OrderHistoryDetailScreen Error: ${orderSnapshot.error}");
            }
            return const Center(child: Text('Lỗi tải thông tin đơn hàng. Vui lòng thử lại.'));
          }

          final order = orderSnapshot.data!;

          return SingleChildScrollView(
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
                _buildInfoRow(Icons.phone, 'SĐT: ${order.customerPhoneNumber}'),
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
                if (order.items.isEmpty)
                  const Center(
                    child: Text("Không có sản phẩm nào trong đơn hàng này."),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      final double lineItemTotal = item.productPrice * item.productQuantity;
                      return buildDetailItem(
                        item.productImageUrl,
                        item.productName,
                        '${item.productPrice.toStringAsFixed(0)}đ',
                        item.productQuantity,
                        lineItemTotal,
                      );
                    },
                  ),
                const Divider(height: 25, thickness: 1),

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

                Row(
                  children: [
                    // Nút "Hủy đơn hàng" (Chỉ hiển thị và kích hoạt khi trạng thái là "Chờ xác nhận")
                    if (order.status == 'Chờ xác nhận')
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFBC132C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isCancelling
                              ? null
                              : () => _confirmCancelOrder(order.id),
                          child: _isCancelling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Hủy đơn hàng',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),

                    // Khoảng cách giữa 2 nút nếu cả 2 cùng hiển thị

                    if (order.status == 'Chờ xác nhận' && order.status == 'Đã hủy') // Điều kiện này không bao giờ đúng vì 2 trạng thái khác nhau
                      const SizedBox(width: 10),
                    // Nút "Đặt lại" (Chỉ hiển thị khi trạng thái là "Đã hủy")
                    if (order.status == 'Đã hủy')
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBC132C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.15),
                          ),
                          onPressed: _isCancelling
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Chức năng đặt lại đang phát triển.')),
                                  );
                                },
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
    Timestamp orderDate,
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
                  // Thay đổi màu nền của badge trạng thái
                  color: status == "Đã giao hàng"
                      ? Colors.green[100] // Màu nền xanh nhạt cho "Đã giao hàng"
                      : (status.toLowerCase().contains("hủy")
                          ? Colors.red[100] // Màu nền đỏ nhạt cho "Hủy"
                          : Colors.orange[100]), // Màu nền cam nhạt cho các trạng thái khác (chờ xác nhận, đang xử lý)
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    // Thay đổi màu chữ của badge trạng thái
                    color: status == "Đã giao hàng"
                        ? Colors.green[800] // Màu chữ xanh đậm cho "Đã giao hàng"
                        : (status.toLowerCase().contains("hủy")
                            ? Colors.red[800] // Màu chữ đỏ đậm cho "Hủy"
                            : Color(0xFFBC132C)), // Màu chữ cam đậm cho các trạng thái khác
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