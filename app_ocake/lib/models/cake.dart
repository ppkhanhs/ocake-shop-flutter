import 'package:cloud_firestore/cloud_firestore.dart';

class Cake {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageAssetPath; // Đổi tên cho rõ ràng, đây là đường dẫn asset
  final bool isAvailable;
  final String? categoryId;
  final String? categoryName;
  final double? discountPrice;
  final bool? isBestSeller;
  final bool? isHotDeal;

  Cake({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageAssetPath, // Sử dụng tên mới
    required this.isAvailable,
    this.categoryId,
    this.categoryName,
    this.discountPrice,
    this.isBestSeller,
    this.isHotDeal,
  });

  factory Cake.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Cake(
      id: doc.id,
      name: data['name'] as String? ?? 'Tên không xác định',
      description: data['description'] as String? ?? 'Không có mô tả',
      price: _parseDouble(data['price']),
      // Giả sử trường trong Firestore vẫn tên là 'imageUrl' nhưng chứa đường dẫn asset
      imageAssetPath: data['imageUrl'] as String? ?? 'assets/images/cake.png',
      isAvailable: data['isAvailable'] as bool? ?? false,
      categoryId: data['categoryId'] as String?,
      categoryName:
          data['category'] as String? ?? data['categoryName'] as String?,
      discountPrice: (data['discountPrice'] as num?)?.toDouble(),
      isBestSeller: data['isBestSeller'] as bool?,
      isHotDeal: data['isHotDeal'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      // Khi lưu vào Firestore, trường vẫn có thể tên là 'imageUrl'
      'imageUrl': imageAssetPath,
      'isAvailable': isAvailable,
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryName != null) 'category': categoryName,
      if (discountPrice != null) 'discountPrice': discountPrice,
      if (isBestSeller != null) 'isBestSeller': isBestSeller,
      if (isHotDeal != null) 'isHotDeal': isHotDeal,
    };
  }
}
