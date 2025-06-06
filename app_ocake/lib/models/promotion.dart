// lib/models/promotion.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percentage, fixedAmount, unknown }

class Promotion {
  final String id; // Document ID (ví dụ: KM001)
  final String name;
  final String description;
  final DiscountType discountType;
  final double
  discountValue; // Giá trị giảm (số phần trăm hoặc số tiền cố định)
  final Timestamp startDate;
  final Timestamp endDate;
  // Thêm các trường khác nếu cần
  final bool isActive; // Khuyến mãi có đang hoạt động không

  Promotion({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.isActive = true, // Mặc định là active
  });

  factory Promotion.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    DiscountType type = DiscountType.unknown;
    String typeString = data['discountType'] as String? ?? '';
    if (typeString == 'percentage') {
      type = DiscountType.percentage;
    } else if (typeString == 'fixedAmount') {
      type = DiscountType.fixedAmount;
    }

    return Promotion(
      id: doc.id,
      name: data['name'] as String? ?? 'Chương trình khuyến mãi',
      description: data['description'] as String? ?? '',
      discountType: type,
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      startDate: data['startDate'] as Timestamp? ?? Timestamp.now(),
      endDate: data['endDate'] as Timestamp? ?? Timestamp.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  // Phương thức kiểm tra xem khuyến mãi có còn hiệu lực không
  bool get isValid {
    final now = Timestamp.now();
    return isActive &&
        now.compareTo(startDate) >= 0 &&
        now.compareTo(endDate) <= 0;
  }

  // Phương thức tính giá đã giảm
  double calculateDiscountedPrice(double originalPrice) {
    if (!isValid || originalPrice <= 0) {
      return originalPrice; // Trả về giá gốc nếu khuyến mãi không hợp lệ hoặc giá gốc <= 0
    }

    double discountedPrice = originalPrice;
    if (discountType == DiscountType.percentage) {
      if (discountValue > 0 && discountValue <= 100) {
        // Đảm bảo % hợp lệ
        discountedPrice = originalPrice - (originalPrice * discountValue / 100);
      }
    } else if (discountType == DiscountType.fixedAmount) {
      if (discountValue > 0 && discountValue < originalPrice) {
        // Đảm bảo giảm giá không âm
        discountedPrice = originalPrice - discountValue;
      } else if (discountValue >= originalPrice) {
        return 0; // Giá sau giảm là 0 nếu giảm nhiều hơn giá gốc
      }
    }
    return discountedPrice > 0 ? discountedPrice : 0; // Đảm bảo giá không âm
  }
}
