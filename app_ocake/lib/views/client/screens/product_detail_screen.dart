import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final String name;
  final int price;
  final String imageUrl;
  final String description;

  const ProductDetailScreen({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 0;

  @override
  Widget build(BuildContext context) {
    final isAsset = !widget.imageUrl.startsWith('http');

    final List<Map<String, dynamic>> relatedProducts = [
      {
        'name': 'Bánh Caramel Flan',
        'price': 45000,
        'image': 'assets/images/caramel.jpg'
      },
      {
        'name': 'Bánh Macaron Pháp',
        'price': 75000,
        'image': 'assets/images/macaroon.jpg'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isAsset
                    ? Image.asset(widget.imageUrl,
                        height: 250, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(widget.imageUrl,
                        height: 250, width: double.infinity, fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('${widget.price} đ',
                          style: TextStyle(fontSize: 18, color: Colors.green)),
                      SizedBox(height: 16),
                      Text('Mô tả sản phẩm',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(widget.description,
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 24),
                      Text('Sản phẩm liên quan',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: relatedProducts.length,
                          separatorBuilder: (_, __) => SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final product = relatedProducts[index];
                            final isAsset = !product['image']
                                .toString()
                                .startsWith('http');
                            return Container(
                              width: 140,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: isAsset
                                        ? Image.asset(product['image'],
                                            height: 100,
                                            width: 140,
                                            fit: BoxFit.cover)
                                        : Image.network(product['image'],
                                            height: 100,
                                            width: 140,
                                            fit: BoxFit.cover),
                                  ),
                                  SizedBox(height: 8),
                                  Text(product['name'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  Text('${product['price']}đ',
                                      style: TextStyle(color: Colors.green)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.green,
              margin: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _quantity == 0
                    ? () {
                        setState(() {
                          _quantity = 1;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm ${widget.name} vào giỏ hàng'),
                          ),
                        );
                      }
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_quantity > 0) ...[
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (_quantity > 1) {
                              _quantity--;
                            } else {
                              _quantity = 0;
                            }
                          });
                        },
                        icon: Icon(Icons.remove, color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _quantity++;
                          });
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                      ),
                    ] else
                      const Text(
                        "Thêm vào giỏ hàng",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
