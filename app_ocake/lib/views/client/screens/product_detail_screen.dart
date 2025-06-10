import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:app_ocake/models/product.dart';
import '../widgets/product_cart.dart';
import 'package:app_ocake/services/database/session_manager.dart';
// -------------------------------------------------------------

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1; // Mặc định số lượng là 1
  Stream<QuerySnapshot<Map<String, dynamic>>>? _relatedProductsStream;
  bool _isAddingToCart = false; // Trạng thái cho nút thêm vào giỏ hàng

  @override
  void initState() {
    super.initState();
    _loadRelatedProducts();
  }

  void _loadRelatedProducts() {
    if (widget.product.categoryId != null &&
        widget.product.categoryId!.isNotEmpty) {
      _relatedProductsStream =
          FirebaseFirestore.instance
              .collection('products')
              .where(
                'isAvailable',
                isEqualTo: true,
              ) // Chỉ lấy sản phẩm đang bán
              .where('categoryId', isEqualTo: widget.product.categoryId)
              .limit(6) // Giới hạn số lượng
              .snapshots();
    } else {
      _relatedProductsStream = Stream.empty();
      print(
        "Sản phẩm '${widget.product.name}' không có categoryId để tải sản phẩm liên quan.",
      );
    }
  }

  void _navigateToRelatedDetail(BuildContext context, Product relatedProduct) {
    Navigator.pushReplacement(
      // Hoặc push nếu muốn giữ lại lịch sử màn hình chi tiết
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: relatedProduct),
      ),
    );
  }

  Future<void> _handleAddToCart() async {
    if (!widget.product.isAvailable!) {
      // Kiểm tra isAvailable từ Product model
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm này hiện đã hết hàng.')),
      );
      return;
    }
    if (_quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số lượng hợp lệ.')),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    String? customerId = SessionManager.currentCustomerId;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng.'),
        ),
      );
      setState(() {
        _isAddingToCart = false;
      });
      return;
    }

    final DocumentReference cartItemRef = FirebaseFirestore.instance
        .collection('customers')
        .doc(customerId)
        .collection('cartItems')
        .doc(widget.product.id);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(cartItemRef);
        int newQuantity = _quantity; // Số lượng từ _quantity state
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          newQuantity = (data['quantity'] as int? ?? 0) + _quantity;
        }
        Map<String, dynamic> dataToSet = {
          'productId': widget.product.id,
          'name': widget.product.name,
          'price': widget.product.displayPrice,
          'quantity': newQuantity,
          'imageUrl': widget.product.imageAssetPath,
          'addedAt': FieldValue.serverTimestamp(),
        };
        if (snapshot.exists) {
          transaction.update(cartItemRef, {
            'quantity': newQuantity,
            'price': dataToSet['price'],
            'addedAt': dataToSet['addedAt'],
          });
        } else {
          transaction.set(cartItemRef, dataToSet);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm ${widget.product.name} (SL: $_quantity) vào giỏ hàng!',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Lỗi khi thêm ${widget.product.name} vào giỏ: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể thêm vào giỏ. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Lấy giá từ getter của model Product (đã bao gồm logic khuyến mãi)
    double displayPriceToShow = widget.product.displayPrice;
    double? originalPriceToShow = widget.product.originalPriceForDisplay;
    bool isProductActuallyAvailable = widget.product.isAvailable ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Color(0xFFBC132C),
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 100.0,
            ), // Tăng padding cho vừa nút bottom
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'product_image_${widget.product.id}',
                  child: Container(
                    height: 300, // Tăng chiều cao ảnh sản phẩm
                    width: double.infinity,
                    color: Colors.grey[200], // Màu nền placeholder
                    child: Image.asset(
                      widget.product.imageAssetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.bakery_dining_outlined,
                            color: Colors.grey[400],
                            size: 80,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        // Để hiển thị giá và có thể là tag giảm giá
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          if (originalPriceToShow != null) ...[
                            Text(
                              '${originalPriceToShow.toStringAsFixed(0)}đ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: 10),
                          ],
                          Text(
                            '${displayPriceToShow.toStringAsFixed(0)}đ',
                            style: TextStyle(
                              fontSize: 22,
                              color:
                                  originalPriceToShow != null
                                      ? Colors.redAccent
                                      : Color(0xFFBC132C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (originalPriceToShow != null) // Tag giảm giá nhỏ
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${((1 - (displayPriceToShow / originalPriceToShow)) * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (!isProductActuallyAvailable)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "HẾT HÀNG",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                      SizedBox(height: 24),
                      Text(
                        'Thông tin chi tiết',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),

                      if (widget.product.productionDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            'Ngày sản xuất: ${DateFormat('dd/MM/yyyy').format(widget.product.productionDate!.toDate())}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      if (widget.product.expiryDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Hạn sử dụng: ${DateFormat('dd/MM/yyyy').format(widget.product.expiryDate!.toDate())}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      SizedBox(height: 24),

                      Text(
                        'Sản phẩm liên quan cùng danh mục',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 270,
                        child: StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: _relatedProductsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              return Center(child: CircularProgressIndicator());
                            if (snapshot.hasError)
                              return Center(
                                child: Text(
                                  'Không thể tải sản phẩm liên quan.',
                                ),
                              );
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty)
                              return Center(
                                child: Text('Không có sản phẩm nào liên quan.'),
                              );

                            final relatedProducts =
                                snapshot.data!.docs
                                    .map((doc) => Product.fromFirestore(doc))
                                    .where(
                                      (prod) => prod.id != widget.product.id,
                                    )
                                    .toList();

                            if (relatedProducts.isEmpty)
                              return Center(
                                child: Text(
                                  'Không có sản phẩm nào khác liên quan.',
                                ),
                              );

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: relatedProducts.length,
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              itemBuilder: (context, index) {
                                final relatedProd = relatedProducts[index];
                                return Container(
                                  width: 165,
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  child: ProductCart(
                                    product: relatedProd,
                                    onTap:
                                        () => _navigateToRelatedDetail(
                                          context,
                                          relatedProd,
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
              ],
            ),
          ),
          // Nút "Thêm vào giỏ hàng" và điều chỉnh số lượng
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ), // Bo tròn cho đẹp
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100], // Nền cho nút số lượng
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color:
                                _quantity > 1
                                    ? Colors.black54
                                    : Colors.grey[300],
                            size: 26,
                          ),
                          onPressed:
                              _isAddingToCart ||
                                      !isProductActuallyAvailable ||
                                      _quantity <= 1
                                  ? null
                                  : () {
                                    setState(() {
                                      _quantity--;
                                    });
                                  },
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                          ), // Tăng padding
                          child: Text(
                            '$_quantity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color:
                                _isAddingToCart || !isProductActuallyAvailable
                                    ? Colors.grey[300]
                                    : Color(0xFFBC132C),
                            size: 26,
                          ),
                          onPressed:
                              _isAddingToCart || !isProductActuallyAvailable
                                  ? null
                                  : () {
                                    setState(() {
                                      _quantity++;
                                    });
                                  },
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon:
                          _isAddingToCart
                              ? SizedBox.shrink()
                              : Icon(
                                Icons.add_shopping_cart_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      label:
                          _isAddingToCart
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                "Thêm vào giỏ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFBC132C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor:
                            Colors.grey.shade300, // Màu khi bị vô hiệu hóa
                      ),
                      onPressed:
                          _isAddingToCart || !isProductActuallyAvailable
                              ? null
                              : _handleAddToCart,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
