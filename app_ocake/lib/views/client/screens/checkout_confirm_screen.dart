import 'package:flutter/material.dart';
import 'package:app_ocake/models/cart_item.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final String name;
  final String phone;
  final String address;
  final String paymentMethod;
  final double totalAmount;
  final List<CartItem>? orderedItems;

  const OrderConfirmationScreen({
    Key? key, // Thêm Key
    required this.orderId,
    required this.name,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    required this.totalAmount,
    this.orderedItems, // Tham số mới, có thể null nếu không truyền
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xác nhận đơn hàng',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        automaticallyImplyLeading: false, // Không cho phép nút back mặc định
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 100),
                    const SizedBox(height: 16),
                    const Text(
                      'Đặt hàng thành công!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cảm ơn bạn đã mua hàng tại Hỷ Lâm Môn',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- Thông tin đơn hàng (giữ nguyên) ---
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin đơn hàng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.receipt, 'Mã đơn hàng: $orderId'),
                      _buildInfoRow(Icons.person, 'Khách hàng: $name'),
                      _buildInfoRow(Icons.phone, 'SĐT: $phone'),
                      _buildInfoRow(Icons.location_on, 'Địa chỉ: $address'),
                      _buildInfoRow(
                        Icons.payment,
                        'Phương thức TT: $paymentMethod',
                      ), // Viết tắt cho gọn
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tổng tiền: ${totalAmount.toStringAsFixed(0)}đ', // Hiển thị double
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- THÊM PHẦN HIỂN THỊ CHI TIẾT SẢN PHẨM ĐÃ ĐẶT ---
              if (orderedItems != null && orderedItems!.isNotEmpty) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sản phẩm đã đặt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: orderedItems!.length,
                          separatorBuilder:
                              (context, index) =>
                                  Divider(height: 12, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final item = orderedItems![index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      // Giả sử ảnh là asset
                                      item.imageAssetPath,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (c, e, s) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.image_not_supported,
                                            ),
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Số lượng: ${item.quantity}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${(item.price * item.quantity).toStringAsFixed(0)}đ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    // Quay về màn hình đầu tiên của stack (thường là HomeScreen)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text(
                    'Về trang chính',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget để tạo các dòng thông tin cho gọn
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ), // Thêm padding cho mỗi dòng
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green,
            size: 20,
          ), // Kích thước icon nhỏ hơn chút
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
