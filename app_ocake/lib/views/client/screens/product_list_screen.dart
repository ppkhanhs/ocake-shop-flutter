import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_ocake/models/product.dart'; 
import 'package:app_ocake/views/client/widgets/product_cart.dart'; 
import 'package:app_ocake/views/client/screens/product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String? searchQuery;
  final String? categoryId; 
  final String? categoryName;

  const ProductListScreen({
    Key? key,
    this.searchQuery,
    this.categoryId,
    this.categoryName,
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _productsStream;
  List<Product> _products = [];
  bool _isLoading = true; // Trạng thái để quản lý việc tải dữ liệu ban đầu

  @override
  void initState() {
    super.initState();
    _setupProductsStream(); // Thiết lập stream khi màn hình được khởi tạo
  }

  // Phương thức này được gọi khi widget được cập nhật (ví dụ: tham số thay đổi)
  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ cập nhật lại stream nếu các tham số truy vấn thực sự thay đổi
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.categoryId != oldWidget.categoryId) {
      _setupProductsStream();
    }
  }

  // Thiết lập truy vấn Firestore dựa trên các tham số được truyền vào
  void _setupProductsStream() {
    setState(() {
      _isLoading = true; // Bắt đầu trạng thái loading khi thiết lập lại stream
    });

    Query<Map<String, dynamic>> baseQuery =
        FirebaseFirestore.instance.collection('products');

    // Luôn lọc các sản phẩm đang có sẵn
    baseQuery = baseQuery.where('isAvailable', isEqualTo: true);

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      String searchLower = widget.searchQuery!.toLowerCase();
      baseQuery = baseQuery
          .orderBy('nameLowercase')
          .startAt([searchLower])
          .endAt([searchLower + '\uf8ff']);
    } else if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
      baseQuery = baseQuery.where('categoryId', isEqualTo: widget.categoryId);
    } else {
      baseQuery = baseQuery.orderBy('nameLowercase');
    }

    _productsStream = baseQuery.snapshots();

    // Nghe sự kiện stream một lần để lấy dữ liệu ban đầu và tắt loading
    _productsStream!.listen((snapshot) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Tắt loading
          // Chuyển đổi DocumentSnapshot thành đối tượng Product
          _products = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        });
      }
    }, onError: (error) {
      // Xử lý lỗi từ Firestore (ví dụ: lỗi chỉ mục)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("ProductListScreen Firestore Stream Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải sản phẩm: $error')),
      );
    });
  }

  // Hàm điều hướng đến màn hình chi tiết sản phẩm
  void _navigateToDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Xác định tiêu đề AppBar dựa trên tham số truyền vào
    String appBarTitle = 'Sản phẩm';
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      appBarTitle = '${widget.searchQuery}';
    } else if (widget.categoryName != null && widget.categoryName!.isNotEmpty) {
      appBarTitle = '${widget.categoryName}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: const Color(0xFFBC132C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Nút back đơn giản
        ),
      ),
      body: _isLoading // Hiển thị loading nếu đang tải
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty // Hiển thị thông báo nếu không có sản phẩm
              ? Center(
                  child: Text(
                    widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                        ? 'Không tìm thấy sản phẩm nào khớp với tìm kiếm.'
                        : (widget.categoryId != null && widget.categoryId!.isNotEmpty
                            ? 'Không có sản phẩm nào trong danh mục này.'
                            : 'Không có sản phẩm nào.'),
                    textAlign: TextAlign.center,
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCart(
                      product: product,
                      onTap: () => _navigateToDetail(context, product),
                    );
                  },
                ),
    );
  }
}