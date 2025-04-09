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
          'Order History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrangeAccent,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
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
    return Row(
      children: [
        Image.asset("assets/demo/cake.png", width: 50, height: 50),
        const SizedBox(width: 10),
        Expanded(
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    "Order #$orderId",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "\$29.00",
                  style: TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            subtitle: Text(
              "04/10/2023",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                // Navigate to order details screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryDetailScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
