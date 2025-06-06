import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String
  id; // Document ID của cart item trên Firestore (có thể là productId)
  final String productId; // ID của sản phẩm gốc trong collection 'cakes'
  final String name;
  final double price;
  int quantity;
  final String
  imageAssetPath; // Đường dẫn asset, ví dụ: 'assets/images/cake.png'
  bool selected; // Quản lý ở client, không nhất thiết lưu trên Firestore

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageAssetPath,
    this.selected = false, // Mặc định là chưa chọn khi tạo object ở client
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return CartItem(
      id: doc.id, // Lấy ID của document cart item
      productId: data['productId'] as String? ?? '',
      name: data['name'] as String? ?? 'Sản phẩm không tên',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      // Giả sử trên Firestore bạn lưu đường dẫn ảnh asset vào trường 'imageUrl'
      imageAssetPath: data['imageUrl'] as String? ?? 'assets/images/',
      // 'selected' không đọc từ Firestore, sẽ được quản lý ở client
    );
  }

  // Dùng để tạo mới hoặc cập nhật document trên Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageAssetPath, // Lưu đường dẫn asset vào trường 'imageUrl'
      // Không lưu 'selected'
      // Có thể thêm 'addedAt': FieldValue.serverTimestamp() nếu muốn
    };
  }
}
