import 'package:flutter/material.dart';
import 'edit_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  @override
  _ManageProductsScreenState createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  List<Map<String, dynamic>> _products = [
    {
      'name': 'Bánh Mousse Dâu',
      'price': 59000,
      'image': 'assets/images/moussedau.jpg'
    },
    {
      'name': 'Bánh Bông Lan Trứng Muối',
      'price': 69000,
      'image': 'assets/images/banhbonglan.jpg'
    },
  ];

  void _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _products.add(result);
      });
    }
  }

  void _navigateToEditProduct(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(product: _products[index]),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _products[index] = result;
      });
    }
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa bánh này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _products.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý sản phẩm'),
        leading: BackButton(),
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            leading: Image.network(
              product['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
            title: Text(product['name']),
            subtitle: Text('${product['price']}đ'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: const Color.fromARGB(255, 0, 157, 255)),
                  onPressed: () => _navigateToEditProduct(index),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        tooltip: 'Thêm bánh mới',
      ),
    );
  }
}
