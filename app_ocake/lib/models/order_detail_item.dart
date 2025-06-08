class OrderDetailItem {
  final String productId;
  final String productName;
  final double productPrice;
  final int productQuantity;
  final String productImageUrl; // Tên trường phù hợp với Firestore 'imageUrl'

  OrderDetailItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productQuantity,
    required this.productImageUrl,
  });

  // Factory constructor để tạo OrderDetailItem từ một Map
  factory OrderDetailItem.fromMap(Map<String, dynamic> map) {
    return OrderDetailItem(
      productId: map['productId'] as String? ?? '',
      productName: map['name'] as String? ?? 'N/A',
      productPrice: (map['price'] as num?)?.toDouble() ?? 0.0,
      productQuantity: map['quantity'] as int? ?? 0,
      productImageUrl: map['imageUrl'] as String? ?? 'assets/images/placeholder.png', // Đảm bảo khớp với tên field trong Firestore
    );
  }
}