import 'package:app_ocake/views/client/screens/checkout_screen.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Sample cart items with images
  List<Map<String, dynamic>> cartItems = [
    {
      'name': 'Chocolate Cake',
      'price': 50000,
      'quantity': 1,
      'selected': false,
      'image': 'assets/images/cake-1.jpg'
    },
    {
      'name': 'Vanilla Cupcake',
      'price': 35000,
      'quantity': 2,
      'selected': false,
      'image': 'assets/images/cake-1.jpg'
    },
    {
      'name': 'Strawberry Tart',
      'price': 12000,
      'quantity': 1,
      'selected': false,
      'image': 'assets/images/cake-1.jpg'
    },
  ];

  void updateQuantity(int index, int change) {
    setState(() {
      cartItems[index]['quantity'] += change;
      if (cartItems[index]['quantity'] < 1) {
        cartItems[index]['quantity'] = 1;
      }
    });
  }

  void toggleSelection(int index) {
    setState(() {
      cartItems[index]['selected'] = !cartItems[index]['selected'];
    });
  }

  void deleteItem(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  double calculateTotal() {
    return cartItems.fold(
      0,
      (total, item) =>
          item['selected'] ? total + (item['price'] * item['quantity']) : total,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: Key(item['name']),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    deleteItem(index);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item['selected'],
                            onChanged: (value) {
                              toggleSelection(index);
                            },
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(
                              item['image'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text('${item['price']}đ'),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () => updateQuantity(index, -1),
                              ),
                              Text('${item['quantity']}'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () => updateQuantity(index, 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng tiền: ${calculateTotal()}đ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CheckoutScreen()),
                    );
                  },
                  child: Text('Thanh toán'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}