import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isAsset = !imageUrl.startsWith('http');

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
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isAsset
                ? Image.asset(imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover)
                : Image.network(imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('$price đ', style: TextStyle(fontSize: 18, color: Colors.green)),

                  SizedBox(height: 16),
                  Text('Mô tả sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 16)),

                  SizedBox(height: 24),
                  Text('Đánh giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) => Icon(Icons.star, color: Colors.amber)),
                  ),
                  SizedBox(height: 8),
                  Text('"Bánh ngon, mềm mịn, giao hàng nhanh!"', style: TextStyle(fontStyle: FontStyle.italic)),

                  SizedBox(height: 24),
                  Text('Sản phẩm liên quan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: relatedProducts.length,
                      separatorBuilder: (_, __) => SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = relatedProducts[index];
                        final isAsset = !product['image'].toString().startsWith('http');
                        return Container(
                          width: 140,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: isAsset
                                  ? Image.asset(product['image'], height: 100, width: 140, fit: BoxFit.cover)
                                  : Image.network(product['image'], height: 100, width: 140, fit: BoxFit.cover),
                              ),
                              SizedBox(height: 8),
                              Text(product['name'], maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('${product['price']}đ', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm $name vào giỏ hàng')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 140, 255),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.shopping_cart),
                      label: Text("Thêm vào giỏ hàng"),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
