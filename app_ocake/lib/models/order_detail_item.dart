import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailItem {
  final String id; // Document ID của orderDetailItem
  final double lineItemTotal;
  final String productId;
  // Thông tin sản phẩm được nhúng trực tiếp
  final String productName;
  final String productImageUrl; // Đường dẫn asset
  final double productPrice;
  final int productQuantity;

  OrderDetailItem({
    required this.id,
    required this.lineItemTotal,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.productPrice,
    required this.productQuantity,
  });

  factory OrderDetailItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    Map<String, dynamic> productInfo =
        data['productInfo'] as Map<String, dynamic>? ?? {};

    String rawImagePath =
        productInfo['imageUrl'] as String? ?? 'assets/images/placeholder.png';
    // Xử lý dấu '/' ở đầu nếu có
    String finalAssetPath =
        rawImagePath.startsWith('/') ? rawImagePath.substring(1) : rawImagePath;

    return OrderDetailItem(
      id: doc.id,
      lineItemTotal: (data['lineItemTotal'] as num?)?.toDouble() ?? 0.0,
      productId: data['productId'] as String? ?? '',
      productName: productInfo['name'] as String? ?? 'Sản phẩm không tên',
      productImageUrl: finalAssetPath, // Đã xử lý dấu '/'
      productPrice: (productInfo['price'] as num?)?.toDouble() ?? 0.0,
      productQuantity: (productInfo['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
