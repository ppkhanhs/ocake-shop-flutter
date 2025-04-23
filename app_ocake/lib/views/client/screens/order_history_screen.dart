import 'order_history_detail_screen.dart';
import 'package:flutter/material.dart';

class OrderHistoryScreen extends StatelessWidget {
  static const List<String> orderHistory = [
    "12345",
    "67890",
    "54321",
    "09876",
    "13579",
  ];
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đơn hàng',
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
        child: ListView.builder(
          itemCount: orderHistory.length,
          itemBuilder: (context, index) {
            return buildOrderHistoryItem(context, orderHistory[index]);
          },
        ),
      ),
    );
  }

  Widget buildOrderHistoryItem(BuildContext context, String orderId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderHistoryDetailScreen(),
          ),
        );
      },
      child: Row(
        children: [
          Image.asset("assets/images/cake.png", width: 50, height: 50),
          const SizedBox(width: 10),
          Expanded(
            child: ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Mã đơn hàng #$orderId",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                "04/10/2023",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Text(
                "\120.000đ",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
