import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:app_ocake/models/order.dart'; // Import model OrderModel
import 'package:app_ocake/models/order_detail_item.dart';
import 'order_history_detail_screen.dart';
// Import SessionManager từ file bạn đã định nghĩa nó
import 'package:app_ocake/services/database/session_manager.dart'; // HOẶC ĐƯỜNG DẪN ĐÚNG
import 'login_screen.dart'; // Để điều hướng nếu chưa đăng nhập
// -------------------------------------------------------------

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // final FirebaseAuth _auth = FirebaseAuth.instance; // Bỏ
  // User? _currentUser; // Bỏ
  String? _currentCustomerIdFromSession; // Sử dụng customerId từ SessionManager
  Stream<QuerySnapshot<Map<String, dynamic>>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _loadOrdersData(); // Gọi hàm để tải dữ liệu dựa trên SessionManager
  }

  // Hàm này sẽ được gọi lại nếu customerId trong SessionManager thay đổi
  // (ví dụ, khi người dùng đăng nhập/đăng xuất ở màn hình khác và quay lại đây)
  // hoặc nếu bạn muốn có nút "Tải lại"
  void _loadOrdersData() {
    _currentCustomerIdFromSession =
        SessionManager.currentCustomerId; // Lấy từ SessionManager

    if (_currentCustomerIdFromSession != null) {
      print(
        "OrderHistoryScreen: Customer ID from Session: $_currentCustomerIdFromSession",
      );
      // Chỉ khởi tạo stream nếu customerId thực sự thay đổi hoặc stream chưa có
      if (_ordersStream == null || (_ordersStream != null && mounted)) {
        // Điều kiện an toàn hơn
        setState(() {
          // Gọi setState để rebuild StreamBuilder với stream mới
          _ordersStream =
              FirebaseFirestore.instance
                  .collection('orders')
                  .where(
                    'userId',
                    isEqualTo: _currentCustomerIdFromSession!,
                  ) // Quan trọng: Lọc theo customerId đã lưu
                  .orderBy('createdAt', descending: true)
                  .snapshots();
        });
      }
    } else {
      print(
        "OrderHistoryScreen: No customer ID in session. User needs to login.",
      );
      if (mounted) {
        setState(() {
          _ordersStream = null; // Đảm bảo stream bị hủy nếu không có user
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kiểm tra xem customerId trong SessionManager có thay đổi không
    final newSessionCustomerId = SessionManager.currentCustomerId;
    if (newSessionCustomerId != _currentCustomerIdFromSession) {
      print(
        "OrderHistoryScreen: Session Customer ID changed. Reloading orders.",
      );
      _loadOrdersData(); // Tải lại dữ liệu nếu ID thay đổi
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra lại customerId mỗi lần build để đảm bảo cập nhật nếu SessionManager thay đổi
    // và widget này được rebuild bởi một lý do khác trước khi didChangeDependencies kịp chạy
    final customerIdForBuild = SessionManager.currentCustomerId;
    if (customerIdForBuild != _currentCustomerIdFromSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrdersData());
      _currentCustomerIdFromSession = customerIdForBuild;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử đơn hàng',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body:
          _currentCustomerIdFromSession ==
                  null // Kiểm tra customerId từ SessionManager
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Vui lòng đăng nhập để xem lịch sử đơn hàng của bạn.'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ), // Điều hướng về LoginScreen
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Text('Đăng nhập ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
              : (_ordersStream ==
                      null // Trường hợp stream chưa kịp khởi tạo
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _ordersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        print(
                          "OrderHistoryScreen Firestore Error: ${snapshot.error}",
                        );
                        return Center(child: Text('Lỗi tải lịch sử đơn hàng.'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('Bạn chưa có đơn hàng nào.'));
                      }

                      final List<OrderModel> userOrders =
                          snapshot.data!.docs
                              .map((doc) => OrderModel.fromFirestore(doc))
                              .toList();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 8.0,
                        ),
                        child: ListView.builder(
                          itemCount: userOrders.length,
                          itemBuilder: (context, index) {
                            final order = userOrders[index];
                            return buildOrderHistoryItem(context, order);
                          },
                        ),
                      );
                    },
                  )),
    );
  }

  Widget buildOrderHistoryItem(BuildContext context, OrderModel order) {
    String formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(order.orderDate.toDate());
    // Lấy ảnh của sản phẩm đầu tiên trong đơn hàng (nếu có)
    // Đảm bảo model OrderModel của bạn có List<OrderDetailItem> items;
    // và model OrderDetailItem có trường imageAssetPath
    String representativeImage =
        (order.items.isNotEmpty &&
                order
                    .items
                    .first
                    .productImageUrl
                    .isNotEmpty) // Thêm kiểm tra image url không rỗng
            ? order
                .items
                .first
                .productImageUrl // <-- SỬA THÀNH productImageUrl
            : 'assets/images/placeholder_order.png';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OrderHistoryDetailScreen(
                    orderDocumentId: order.id,
                  ), // Truyền Document ID
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  representativeImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (c, e, s) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 30,
                          color: Colors.grey[400],
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mã ĐH: ${order.id}", // <-- SỬA THÀNH order.id
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Ngày đặt: $formattedDate",
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Trạng thái: ${order.status}",
                      style: TextStyle(
                        color:
                            order.status.toLowerCase().contains("hủy")
                                ? Colors.red
                                : (order.status.toLowerCase().contains(
                                          "hoàn thành",
                                        ) ||
                                        order.status.toLowerCase().contains(
                                          "đã giao",
                                        )
                                    ? Colors.green
                                    : Colors.orange),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${order.totalAmount.toStringAsFixed(0)}đ",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
