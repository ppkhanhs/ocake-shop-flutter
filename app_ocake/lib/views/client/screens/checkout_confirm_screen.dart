import 'package:flutter/material.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final String name;
  final String phone;
  final String address;
  final String paymentMethod;
  final int totalAmount;

  const OrderConfirmationScreen({
    required this.orderId,
    required this.name,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    required this.totalAmount,
  });

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
                      Row(
                        children: [
                          const Icon(Icons.receipt, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mã đơn hàng: $orderId',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Khách hàng: $name',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SĐT: $phone',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Địa chỉ: $address',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Phương thức thanh toán: $paymentMethod',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tổng tiền: $totalAmount đ',
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
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
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
}