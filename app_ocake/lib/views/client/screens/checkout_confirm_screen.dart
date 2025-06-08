// app_ocake/views/client/screens/checkout_confirm_screen.dart

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
  final VoidCallback? onNavigateToHomeTab; // <-- NEW: Receive callback

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.name,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    required this.totalAmount,
    this.orderedItems,
    this.onNavigateToHomeTab, // <-- NEW: Receive callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xác nhận đơn hàng',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFFBC132C),
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
                    Icon(Icons.check_circle, color: Color(0xFFBC132C), size: 100),
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
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Color(0xFFBC132C)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tổng tiền: ${totalAmount.toStringAsFixed(0)}đ',
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
                    backgroundColor: Color(0xFFBC132C),
                  ),
                  onPressed: () {
                    // Gọi callback để thay đổi tab trong HomeScreen
                    if (onNavigateToHomeTab != null) {
                      onNavigateToHomeTab!();
                    }
                    // Đảm bảo OrderConfirmationScreen bị pop khỏi navigation stack
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6.0,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Color(0xFFBC132C),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}