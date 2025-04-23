import 'package:flutter/material.dart';

class OrderHistoryDetailScreen extends StatelessWidget {
  const OrderHistoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildStatusOrder("#2221", "Đã giao hàng"),
            Divider(),
            SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                  buildDetailItem("assets/images/cake.png", "Cake", "\25.000đ"),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                "Tổng tiền",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              trailing: const Text(
                "\275.000đ",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  "Đặt lại",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusOrder(String orderId, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              title: Text(
                orderId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              subtitle: Text(
                "04/10/2023",
                style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              trailing: Text(
                status,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDetailItem(String image, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Image.asset(image, width: 50, height: 50),
          const SizedBox(width: 10),
          Expanded(
            child: ListTile(
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                value,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Số lượng: 1",
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
