import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Để sử dụng mapEquals

import 'package:app_ocake/models/order.dart';
import 'package:app_ocake/models/order_detail_item.dart';
import 'order_history_detail_screen.dart';
import 'package:app_ocake/services/database/session_manager.dart';
import 'login_screen.dart';

// NEW: Lớp đơn giản để định nghĩa các tùy chọn lọc
class OrderStatusFilter {
  final String label;
  final IconData icon;
  final String? firestoreStatus;
  final String orderCountsKey;

  const OrderStatusFilter({
    required this.label,
    required this.icon,
    this.firestoreStatus,
    required this.orderCountsKey,
  });
}

class OrderHistoryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHomeTab;

  const OrderHistoryScreen({Key? key, this.onNavigateToHomeTab}) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String? _currentCustomerIdFromSession;
  
  // NEW: Biến trạng thái để lưu bộ lọc hiện tại
  String? _currentFilterStatus; // Trạng thái sẽ được dùng để truy vấn Firestore (null = Tất cả)
  String _currentFilterLabel = 'Tất cả'; // Nhãn hiển thị cho bộ lọc đang chọn

  // Map để lưu số lượng đơn hàng theo trạng thái
  Map<String, int> _orderCounts = {
    'Tổng cộng': 0, // Dùng cho mục "Tất cả"
    'Chờ xác nhận': 0,
    'Chờ vận chuyển': 0,
    'Đang vận chuyển': 0,
    'Đánh giá': 0,
  };

  // NEW: Danh sách các tùy chọn lọc trạng thái
  final List<OrderStatusFilter> _filterOptions = const [
    OrderStatusFilter(label: 'Tất cả', icon: Icons.list_alt, firestoreStatus: null, orderCountsKey: 'Tổng cộng'),
    OrderStatusFilter(label: 'Chờ xác nhận', icon: Icons.account_balance_wallet_outlined, firestoreStatus: 'Chờ xác nhận', orderCountsKey: 'Chờ xác nhận'),
    OrderStatusFilter(label: 'Chờ vận chuyển', icon: Icons.archive_outlined, firestoreStatus: 'Chờ vận chuyển', orderCountsKey: 'Chờ vận chuyển'), // Điều chỉnh firestoreStatus theo DB của bạn
    OrderStatusFilter(label: 'Đang vận chuyển', icon: Icons.local_shipping_outlined, firestoreStatus: 'Đang vận chuyển', orderCountsKey: 'Đang vận chuyển'), // Điều chỉnh firestoreStatus theo DB của bạn
    OrderStatusFilter(label: 'Đánh giá', icon: Icons.star_outline, firestoreStatus: 'Hoàn thành', orderCountsKey: 'Đánh giá'), // Điều chỉnh firestoreStatus theo DB của bạn (ví dụ: 'Hoàn thành' hoặc 'Đã giao hàng')
  ];


  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Đổi tên hàm để rõ ràng hơn
  }

  void _loadInitialData() {
    _currentCustomerIdFromSession = SessionManager.currentCustomerId;

    if (_currentCustomerIdFromSession != null) {
      print("OrderHistoryScreen: Customer ID from Session: $_currentCustomerIdFromSession");
      // Không gán _ordersStream trực tiếp ở đây, mà dùng getter _filteredOrdersStream
      // setState để đảm bảo StreamBuilder được rebuild khi _currentCustomerIdFromSession thay đổi
      setState(() {
        _currentFilterStatus = null; // Đặt bộ lọc mặc định là 'Tất cả'
        _currentFilterLabel = 'Tất cả';
        // Reset counts
        _orderCounts = {'Tổng cộng': 0, 'Chờ xác nhận': 0, 'Chờ vận chuyển': 0, 'Đang vận chuyển': 0, 'Đánh giá': 0};
      });
    } else {
      print("OrderHistoryScreen: No customer ID in session. User needs to login.");
      if (mounted) {
        setState(() {
          // Reset trạng thái nếu chưa đăng nhập
          _currentFilterStatus = null;
          _currentFilterLabel = 'Tất cả';
          _orderCounts = {'Tổng cộng': 0, 'Chờ xác nhận': 0, 'Chờ vận chuyển': 0, 'Đang vận chuyển': 0, 'Đánh giá': 0};
        });
      }
    }
  }

  // NEW: Getter để lấy Stream Query dựa trên bộ lọc hiện tại
  Stream<QuerySnapshot<Map<String, dynamic>>> get _filteredOrdersStream {
    if (_currentCustomerIdFromSession == null) {
      // Trả về một stream rỗng nếu chưa có customer ID
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: _currentCustomerIdFromSession!);

    if (_currentFilterStatus != null) {
      // Áp dụng bộ lọc trạng thái nếu có
      baseQuery = baseQuery.where('status', isEqualTo: _currentFilterStatus);
    }

    // Luôn sắp xếp theo ngày đặt hàng
    baseQuery = baseQuery.orderBy('orderDate', descending: true);

    return baseQuery.snapshots();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSessionCustomerId = SessionManager.currentCustomerId;
    if (newSessionCustomerId != _currentCustomerIdFromSession) {
      print("OrderHistoryScreen: Session Customer ID changed. Reloading orders.");
      _loadInitialData(); // Tải lại dữ liệu nếu ID thay đổi
    }
  }

  // Hàm tính toán số lượng đơn hàng theo trạng thái (từ danh sách đã parse)
  void _updateOrderCounts(List<OrderModel> orders) {
    Map<String, int> counts = {
      'Tổng cộng': 0,
      'Chờ xác nhận': 0,
      'Chờ vận chuyển': 0,
      'Đang vận chuyển': 0,
      'Đánh giá': 0,
    };

    for (var order in orders) {
      String status = order.status;
      counts['Tổng cộng'] = counts['Tổng cộng']! + 1; // Đếm tổng cộng

      // Điều chỉnh các chuỗi trạng thái này để khớp chính xác với Firebase của bạn
      if (status == 'Chờ xác nhận') {
        counts['Chờ xác nhận'] = counts['Chờ xác nhận']! + 1;
      } else if (status == 'Chờ vận chuyển' || status == 'Chờ vận chuyển') {
        counts['Chờ vận chuyển'] = counts['Chờ vận chuyển']! + 1;
      } else if (status == 'Đang vận chuyển') {
        counts['Đang vận chuyển'] = counts['Đang vận chuyển']! + 1;
      } else if (status == 'Đã giao hàng' || status == 'Hoàn thành') {
        counts['Đánh giá'] = counts['Đánh giá']! + 1;
      }
    }

    // Cập nhật _orderCounts trong setState chỉ khi có sự thay đổi để tránh rebuild không cần thiết
    if (mounted && !mapEquals(_orderCounts, counts)) {
      setState(() {
        _orderCounts = counts;
      });
    }
  }

  // Widget để xây dựng từng mục thống kê trạng thái (đã có onTap)
  Widget _buildStatusItem(OrderStatusFilter filterOption) {
    final int count = _orderCounts[filterOption.orderCountsKey] ?? 0;
    final bool isSelected = _currentFilterStatus == filterOption.firestoreStatus;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Khi nhấn vào, cập nhật bộ lọc và refresh UI
          setState(() {
            _currentFilterStatus = filterOption.firestoreStatus;
            _currentFilterLabel = filterOption.label;
          });
          print('Đã chọn bộ lọc: ${filterOption.label}');
        },
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(filterOption.icon, size: 35, color: isSelected ? const Color(0xFFBC132C) : Colors.grey[700]), // Icon thay đổi màu khi chọn
                if (count > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              filterOption.label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFFBC132C) : Colors.grey[800], // Label thay đổi màu khi chọn
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget tổng hợp phần "Đơn mua" thống kê trạng thái
  Widget _buildOrderStatusSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đơn mua',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _filterOptions.map((option) => _buildStatusItem(option)).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerIdForBuild = SessionManager.currentCustomerId;
    if (customerIdForBuild != _currentCustomerIdFromSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
      _currentCustomerIdFromSession = customerIdForBuild;
    }

    // UI khi chưa đăng nhập
    if (_currentCustomerIdFromSession == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đơn hàng', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: const Color(0xFFBC132C),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Vui lòng đăng nhập để xem lịch sử đơn hàng của bạn.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Đăng nhập ngay'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBC132C)),
              ),
            ],
          ),
        ),
      );
    }

    // UI hiển thị dữ liệu lịch sử đơn hàng
    return Scaffold(
      appBar: AppBar(
        title: Text(' $_currentFilterLabel', style: const TextStyle(color: Colors.white)), // Tiêu đề AppBar hiển thị bộ lọc
        centerTitle: true,
        backgroundColor: const Color(0xFFBC132C),
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
      body: Column(
        children: [
          _buildOrderStatusSummary(), // PHẦN THỐNG KÊ ĐƠN HÀNG Ở TRÊN CÙNG
          Expanded( // Expanded để StreamBuilder và ListView chiếm hết không gian còn lại
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _filteredOrdersStream, // SỬ DỤNG STREAM ĐÃ LỌC
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("OrderHistoryScreen Firestore Stream Error: ${snapshot.error}");
                  return Center(child: Text('Lỗi tải lịch sử đơn hàng: ${snapshot.error.toString().split(':')[0]}.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Bạn chưa có đơn hàng nào với trạng thái này.')); // Thay đổi thông báo
                }

                List<OrderModel> userOrders = [];
                // Sử dụng biến cục bộ để đếm số lượng cho snapshot hiện tại (đếm tổng cộng)
                Map<String, int> tempCountsForSummary = {
                  'Tổng cộng': 0, 'Chờ xác nhận': 0, 'Chờ vận chuyển': 0, 'Đang vận chuyển': 0, 'Đánh giá': 0,
                };

                try {
                  userOrders = snapshot.data!.docs.map((doc) {
                    try {
                      final order = OrderModel.fromFirestore(doc);
                      // Đếm số lượng đơn hàng cho summary (dù stream đã lọc, vẫn đếm từ tất cả để tổng hợp)
                      tempCountsForSummary['Tổng cộng'] = tempCountsForSummary['Tổng cộng']! + 1;
                      if (order.status == 'Chờ xác nhận') {
                        tempCountsForSummary['Chờ xác nhận'] = tempCountsForSummary['Chờ xác nhận']! + 1;
                      } else if (order.status == 'Đã xử lý' || order.status == 'Đang chuẩn bị') {
                        tempCountsForSummary['Chờ vận chuyển'] = tempCountsForSummary['Chờ vận chuyển']! + 1;
                      } else if (order.status == 'Đang giao hàng') {
                        tempCountsForSummary['Đang vận chuyển'] = tempCountsForSummary['Đang vận chuyển']! + 1;
                      } else if (order.status == 'Hoàn thành' || order.status == 'Đã giao hàng') {
                        tempCountsForSummary['Đánh giá'] = tempCountsForSummary['Đánh giá']! + 1;
                      }
                      return order;
                    } catch (e) {
                      print("OrderHistoryScreen Parsing error for document ${doc.id}: $e");
                      return null;
                    }
                  }).whereType<OrderModel>().toList();

                  if (userOrders.isEmpty && _currentFilterStatus != null) {
                     // Nếu không có đơn hàng nào sau khi lọc, hiển thị thông báo
                     return const Center(child: Text('Không có đơn hàng nào với trạng thái này.'));
                  }
                  if (userOrders.isEmpty && _currentFilterStatus == null) {
                    return const Center(child: Text('Bạn chưa có đơn hàng nào.'));
                  }

                  // Cập nhật _orderCounts trong setState nếu có thay đổi
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !mapEquals(_orderCounts, tempCountsForSummary)) {
                      setState(() {
                        _orderCounts = tempCountsForSummary;
                      });
                    }
                  });

                } catch (e) {
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
          ),
        ],
      ),
    );
  }

  // Widget để xây dựng từng item lịch sử đơn hàng
   Widget buildOrderHistoryItem(BuildContext context, OrderModel order) {
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate.toDate());

    String representativeImage = (order.items.isNotEmpty && order.items.first.productImageUrl.isNotEmpty)
        ? order.items.first.productImageUrl
        : 'assets/images/placeholder_order.png';

    String firstProductName = order.items.isNotEmpty
        ? order.items.first.productName
        : 'Đơn hàng trống';

    int otherProductsCount = order.items.length > 1 ? order.items.length - 1 : 0;
    String otherProductsText = otherProductsCount > 0
        ? 'và ${otherProductsCount} sản phẩm khác'
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
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
                child: Image.asset(
                  representativeImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.receipt_long_outlined, size: 30, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstProductName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (otherProductsCount > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            otherProductsText,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                        ],
                      )
                    else
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
                      maxLines: 1, // <<< THÊM DÒNG NÀY
                      overflow: TextOverflow.ellipsis, // <<< THÊM DÒNG NÀY
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