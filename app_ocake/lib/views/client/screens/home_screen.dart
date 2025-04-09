import 'package:flutter/material.dart';
import 'product_detail_screen.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  final List<String> categories = [
    'Bánh Mousse',
    'Bánh Tiramisu',
    'Bánh Bông Lan',
    'Bánh Sinh Nhật',
    'Bánh Creepe sầu riêng',
  ];

  final List<Map<String, dynamic>> hotDeals = [
    {
      'name': 'Bánh Cheesecake',
      'price': 75000,
      'discount': 59000,
      'image': 'assets/images/cheesecake.jpg',
    },
    {
      'name': 'Bánh Socola Lava',
      'price': 70000,
      'discount': 55000,
      'image': 'assets/images/socolalava.jpg',
    },
  ];

  final List<Map<String, dynamic>> bestSellers = [
    {
      'name': 'Bánh Mousse Dâu',
      'price': 59000,
      'image': 'assets/images/moussedau.jpg',
    },
    {
      'name': 'Bánh Bông Lan Trứng Muối',
      'price': 69000,
      'image': 'assets/images/banhbonglan.jpg',
    },
  ];

  final List<Map<String, dynamic>> allCakes = [
    {
      'name': 'Bánh Tiramisu',
      'price': 65000,
      'image': 'assets/images/tiramisu.png',
    },
    {
      'name': 'Bánh Cupcake Socola',
      'price': 39000,
      'image': 'assets/images/cupcakesocola.png',
    },
    {
      'name': 'Bánh Mousse Dâu',
      'price': 59000,
      'image': 'assets/images/moussedau.jpg',
    },
    {
      'name': 'Bánh Bông Lan Trứng Muối',
      'price': 69000,
      'image': 'assets/images/banhbonglan.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Bạn đang thèm món bánh gì?',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Text('Deal hot mỗi ngày',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: hotDeals.length,
                itemBuilder: (context, index) {
                  final cake = hotDeals[index];
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 12),
                    child: CakeCard(
                      name: cake['name'],
                      price: cake['discount'],
                      imageUrl: cake['image'],
                      originalPrice: cake['price'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              name: cake['name'],
                              price: cake['discount'],
                              imageUrl: cake['image'],
                              description: 'Deal hot: ${cake['name']} giảm giá cực sốc!',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text('Danh mục sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    margin: EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/category_${index + 1}.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          categories[index],
                          style: TextStyle(fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Text('Sản phẩm được ưa thích',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Container(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemCount: bestSellers.length,
                itemBuilder: (context, index) {
                  final cake = bestSellers[index];
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(right: 12),
                    child: CakeCard(
                      name: cake['name'],
                      price: cake['price'],
                      imageUrl: cake['image'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              name: cake['name'],
                              price: cake['price'],
                              imageUrl: cake['image'],
                              description: 'Bánh ${cake['name']} là sản phẩm được yêu thích nhất!',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Text('Các sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: allCakes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final cake = allCakes[index];
                  return CakeCard(
                    name: cake['name'],
                    price: cake['price'],
                    imageUrl: cake['image'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            name: cake['name'],
                            price: cake['price'],
                            imageUrl: cake['image'],
                            description: 'Bánh ${cake['name']} thơm ngon, hoàn hảo cho mọi dịp.',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CakeCard extends StatelessWidget {
  final String name;
  final int price;
  final String imageUrl;
  final int? originalPrice;
  final VoidCallback onTap;

  const CakeCard({
    required this.name,
    required this.price,
    required this.imageUrl,
    this.originalPrice,
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
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: isAsset
                  ? Image.asset(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: originalPrice != null
                  ? Row(
                      children: [
                        Text(
                          '${originalPrice}đ',
                          style: TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${price}đ',
                          style: TextStyle(
                              color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : Text(
                      '${price}đ',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600),
                    ),
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: EdgeInsets.all(10),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã thêm $name vào giỏ hàng')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
