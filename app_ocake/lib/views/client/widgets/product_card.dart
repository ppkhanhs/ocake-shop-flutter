import 'package:flutter/material.dart';

class CakeCard extends StatelessWidget {
  final String name;
  final int price;
  final String imageUrl;
  final VoidCallback onTap;

  const CakeCard({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAsset = !imageUrl.startsWith('http');

    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh bánh
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: isAsset
                  ? Image.asset(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
            ),

            // Nội dung
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${price.toString()}đ',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                    Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: IconButton(
                        icon: Icon(Icons.add_shopping_cart, color: Colors.greenAccent),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã thêm $name vào giỏ hàng')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
