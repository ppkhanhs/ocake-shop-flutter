// lib/models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'promotion.dart'; // Import Promotion model

class Product {
  final String id;
  final String? categoryId;
  final String description;
  final String nameLowercase;
  final Timestamp? expiryDate;
  final String imageAssetPath;
  final Timestamp? importDate;
  final String name;
  final double price; // Giá gốc
  final Timestamp? productionDate;
  final String?
  promotionIds; // Có thể là một ID hoặc nhiều ID (cần xử lý phức tạp hơn nếu nhiều)

  final bool? isAvailable;
  // Bỏ discountPrice vì nó sẽ được tính toán
  // final double? discountPrice;
  final bool? isBestSeller;

  // (Tùy chọn) Thêm một trường để lưu đối tượng Promotion đã được tải
  // Hoặc một trường để lưu giá đã giảm sau khi tính toán.
  // Việc này giúp tránh phải tính toán lại nhiều lần.
  Promotion? activePromotion; // Lưu khuyến mãi đang được áp dụng (nếu có)
  double? calculatedDiscountPrice; // Lưu giá đã giảm để hiển thị

  Product({
    required this.id,
    this.categoryId,
    required this.description,
    this.expiryDate,
    required this.imageAssetPath,
    this.importDate,
    required this.name,
    required this.price,
    required this.nameLowercase,
    this.productionDate,
    this.promotionIds,
    this.isAvailable,
    this.isBestSeller,
    this.activePromotion, // Thêm vào constructor nếu bạn muốn gán từ ngoài
    this.calculatedDiscountPrice, // Thêm vào constructor nếu bạn muốn gán từ ngoài
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError('Product document data is null for ID: ${doc.id}');
    }

    // Đọc trường nameLowercase, nếu không có, tự động tạo từ name (cho dữ liệu cũ)
    final String name = data['name'] as String? ?? 'N/A';
    final String nameLowercase = (data['nameLowercase'] as String?) ?? name.toLowerCase(); // <--- ĐỌC HOẶC TẠO

    return Product(
      id: doc.id,
      name: name,
      nameLowercase: nameLowercase,
      description: data['description'] as String? ?? 'N/A',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageAssetPath: data['imageUrl'] as String? ?? 'assets/images/placeholder.png',
      categoryId: data['categoryId'] as String? ?? '',
      promotionIds: data['promotionIds'] as String?,
      isAvailable: data['isAvailable'] as bool? ?? true,
      isBestSeller: data['isBestSeller'] as bool? ?? false,
    );
  }

  // Phương thức để tính và cập nhật giá đã giảm (cần được gọi sau khi tải Promotion)
  void calculateAndSetDiscountPrice(Promotion? promotion) {
    activePromotion = promotion; // Lưu lại promotion đã dùng (nếu có)
    if (promotion != null && promotion.isValid) {
      calculatedDiscountPrice = promotion.calculateDiscountedPrice(price);
    } else {
      calculatedDiscountPrice =
          null; // Không có giảm giá hoặc promotion không hợp lệ
    }
  }


  double get displayPrice {
    return calculatedDiscountPrice ?? price;
  }

  double? get originalPriceForDisplay {
    return (calculatedDiscountPrice != null && calculatedDiscountPrice! < price)
        ? price
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      'description': description,
      if (expiryDate != null) 'expiryDate': expiryDate,
      'imageUrl':
          imageAssetPath.startsWith('assets/')
              ? "/$imageAssetPath"
              : imageAssetPath,
      if (importDate != null) 'importDate': importDate,
      'name': name,
      'price': price,
      if (productionDate != null) 'productionDate': productionDate,
      if (promotionIds != null) 'promotionIds': promotionIds,
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (isBestSeller != null) 'isBestSeller': isBestSeller,
      // Không lưu discountPrice, activePromotion, calculatedDiscountPrice vào Firestore vì chúng là dữ liệu dẫn xuất
    };
  }
}
