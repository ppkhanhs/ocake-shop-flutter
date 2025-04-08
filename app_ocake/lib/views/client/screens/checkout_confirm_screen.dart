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
        title: Text('Xác nhận đơn hàng'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(Icons.check_circle, color: Colors.green, size: 100),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Đặt hàng thành công!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 30),
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
                      Text('🧾 Mã đơn hàng: $orderId',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 12),
                      Text('👤 Khách hàng: $name', style: TextStyle(fontSize: 16)),
                      Text('📞 SĐT: $phone', style: TextStyle(fontSize: 16)),
                      Text('🏠 Địa chỉ: $address', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 12),
                      Text('💳 Phương thức thanh toán: $paymentMethod',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 12),
                      Text('💰 Tổng tiền: $totalAmount đ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
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