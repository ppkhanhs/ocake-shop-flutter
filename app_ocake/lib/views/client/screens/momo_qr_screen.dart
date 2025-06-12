// lib/views/client/screens/momo_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:app_ocake/models/cart_item.dart'; // Import CartItem model
import 'checkout_confirm_screen.dart'; // Import OrderConfirmationScreen

class MomoQrScreen extends StatelessWidget {
  final double totalAmount;
  final String orderId;
  final String name; // NEW
  final String phone; // NEW
  final String address; // NEW
  final String paymentMethod; // NEW
  final List<CartItem>? orderedItems; // NEW
  final VoidCallback? onNavigateToHomeTab; // NEW

  const MomoQrScreen({
    Key? key,
    required this.totalAmount,
    required this.orderId, // Bây giờ orderId là required
    required this.name, // NEW
    required this.phone, // NEW
    required this.address, // NEW
    required this.paymentMethod, // NEW
    this.orderedItems, // NEW
    this.onNavigateToHomeTab, // NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán MoMo'),
        backgroundColor: const Color(0xFFBC132C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Quét mã QR để thanh toán',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Mã đơn hàng: $orderId',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                'Tổng tiền: ${totalAmount.toStringAsFixed(0)}đ',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFBC132C)),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/momo_qr.png', // <-- ĐƯỜNG DẪN ĐẾN ẢNH QR MOMO CỦA BẠN
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text('Không tìm thấy mã QR MoMo', textAlign: TextAlign.center),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mở ứng dụng MoMo và quét mã QR trên để hoàn tất thanh toán.\nĐơn hàng sẽ được xác nhận sau khi nhận được thanh toán.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Nút "Thanh toán thành công"
              ElevatedButton.icon(
                onPressed: () {
                  // Điều hướng đến OrderConfirmationScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderConfirmationScreen(
                        orderId: orderId,
                        name: name,
                        phone: phone,
                        address: address,
                        paymentMethod: paymentMethod,
                        totalAmount: totalAmount,
                        orderedItems: orderedItems,
                        onNavigateToHomeTab: onNavigateToHomeTab,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Thanh toán thành công', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Màu xanh cho nút thành công
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              // Nút quay lại (nếu người dùng muốn quay lại mà chưa thanh toán)
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Quay lại CheckoutScreen
                },
                child: const Text('Quay lại trang xác nhận', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}