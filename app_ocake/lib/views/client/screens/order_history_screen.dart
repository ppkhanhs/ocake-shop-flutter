import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import model OrderModel và OrderDetailItem
import 'package:app_ocake/models/order.dart';
import 'package:app_ocake/models/order_detail_item.dart'; // Đảm bảo import này đúng
import 'order_history_detail_screen.dart'; // Nếu bạn có màn hình chi tiết đơn hàng
import 'package:app_ocake/services/database/session_manager.dart';
import 'login_screen.dart'; // Để điều hướng nếu chưa đăng nhập

class OrderHistoryScreen extends StatefulWidget {
  // Thêm callback để điều hướng về Home tab của HomeScreen
  final VoidCallback? onNavigateToHomeTab;

  const OrderHistoryScreen({Key? key, this.onNavigateToHomeTab}) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String? _currentCustomerIdFromSession;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _loadOrdersData();
  }

  void _loadOrdersData() {
    _currentCustomerIdFromSession = SessionManager.currentCustomerId;

    if (_currentCustomerIdFromSession != null) {
      print("OrderHistoryScreen: Customer ID from Session: $_currentCustomerIdFromSession");
      // Khởi tạo stream hoặc cập nhật nếu customerId thay đổi
      // Đặt trong setState để StreamBuilder phản ứng
      setState(() {
        _ordersStream = FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: _currentCustomerIdFromSession!)
            .orderBy('orderDate', descending: true) // Sử dụng 'orderDate' thay vì 'createdAt' nếu đó là trường bạn dùng trong Firestore
            .snapshots();
      });
    } else {
      print("OrderHistoryScreen: No customer ID in session. User needs to login.");
      if (mounted) {
        setState(() {
          _ordersStream = null;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSessionCustomerId = SessionManager.currentCustomerId;
    if (newSessionCustomerId != _currentCustomerIdFromSession) {
      print("OrderHistoryScreen: Session Customer ID changed. Reloading orders.");
      _loadOrdersData(); // Tải lại dữ liệu nếu ID thay đổi
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra lại customerId mỗi lần build để đảm bảo cập nhật nếu SessionManager thay đổi
    final customerIdForBuild = SessionManager.currentCustomerId;
    if (customerIdForBuild != _currentCustomerIdFromSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrdersData());
      _currentCustomerIdFromSession = customerIdForBuild;
    }

    // UI khi chưa đăng nhập
    if (_currentCustomerIdFromSession == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đơn hàng', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Color(0xFFBC132C),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Dùng callback để quay về Home tab nếu có
              if (widget.onNavigateToHomeTab != null) {
                widget.onNavigateToHomeTab!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Vui lòng đăng nhập để xem lịch sử đơn hàng của bạn.'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Đảm bảo điều hướng về LoginScreen và xóa tất cả route trước đó
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text('Đăng nhập ngay'),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFBC132C)),
              ),
            ],
          ),
        ),
      );
    }

    // UI khi đang tải hoặc không có stream
    if (_ordersStream == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đơn hàng', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Color(0xFFBC132C),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (widget.onNavigateToHomeTab != null) {
                widget.onNavigateToHomeTab!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // UI hiển thị dữ liệu lịch sử đơn hàng
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFFBC132C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onNavigateToHomeTab != null) {
              widget.onNavigateToHomeTab!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // In lỗi chi tiết ra console
            print("OrderHistoryScreen Firestore Stream Error: ${snapshot.error}");
            return Center(child: Text('Lỗi tải lịch sử đơn hàng: ${snapshot.error.toString().split(':')[0]}.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bạn chưa có đơn hàng nào.'));
          }

          List<OrderModel> userOrders = [];
          try {
            // Bắt lỗi khi parse từng document
            userOrders = snapshot.data!.docs.map((doc) {
              try {
                return OrderModel.fromFirestore(doc);
              } catch (e) {
                print("OrderHistoryScreen Parsing error for document ${doc.id}: $e");
                // Nếu một document bị lỗi, bạn có thể trả về một OrderModel 'lỗi' hoặc bỏ qua nó
                // Ở đây tôi chọn bỏ qua để tránh crash toàn bộ danh sách
                return null;
              }
            }).whereType<OrderModel>().toList(); // Lọc bỏ các giá trị null

            // Nếu sau khi lọc mà danh sách rỗng, có thể do tất cả đều lỗi
            if (userOrders.isEmpty) {
              return const Center(child: Text('Không thể hiển thị đơn hàng nào do lỗi dữ liệu.'));
            }

          } catch (e) {
            // Lỗi xảy ra ở mức tổng hợp (ví dụ: snapshot.data!.docs là null)
            print("OrderHistoryScreen General parsing error: $e");
            return Center(
              child: Text(
                'Lỗi xử lý dữ liệu đơn hàng: ${e.toString().split(':')[0]}.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: ListView.builder(
              itemCount: userOrders.length,
              itemBuilder: (context, index) {
                final order = userOrders[index];
                return buildOrderHistoryItem(context, order);
              },
            ),
          );
        },
      ),
    );
  }

  // Widget để xây dựng từng item lịch sử đơn hàng
  Widget buildOrderHistoryItem(BuildContext context, OrderModel order) {
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate.toDate());

    // Lấy ảnh từ sản phẩm đầu tiên trong đơn hàng, hoặc ảnh placeholder
    String representativeImage = (order.items.isNotEmpty && order.items.first.productImageUrl.isNotEmpty)
        ? order.items.first.productImageUrl
        : 'assets/images/placeholder_order.png'; // Đảm bảo ảnh này tồn tại

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // Điều hướng đến màn hình chi tiết đơn hàng
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderHistoryDetailScreen(
                orderDocumentId: order.id,
              ),
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
                child: Image.asset( // Sử dụng Image.asset vì ảnh bạn lưu là asset
                  representativeImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.receipt_long_outlined, size: 30, color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mã ĐH: ${order.id}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ngày đặt: $formattedDate",
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Trạng thái: ${order.status}",
                      style: TextStyle(
                        color: order.status.toLowerCase().contains("hủy")
                            ? Colors.red
                            : (order.status.toLowerCase().contains("hoàn thành") || order.status.toLowerCase().contains("đã giao")
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
                      color: Color(0xFFBC132C),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
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