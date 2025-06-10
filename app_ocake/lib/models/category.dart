import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String imageAssetPath; // Đổi tên cho rõ ràng
  // final String description;
  // final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.imageAssetPath, // Sử dụng tên mới
    // required this.description,
    // required this.sortOrder,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    String rawImagePath =
        data['imageUrl'] as String? ?? 'assets/images/category_placeholder.png';
    // --- XỬ LÝ ĐƯỜNG DẪN ---
    String finalAssetPath = rawImagePath;
    if (rawImagePath.startsWith('/')) {
      finalAssetPath = rawImagePath.substring(1);
    }

    return Category(
      id: doc.id,
      name: data['name'] as String? ?? 'Chưa đặt tên',
      // Giả sử trường trong Firestore vẫn tên là 'imageUrl' nhưng chứa đường dẫn asset
      imageAssetPath: finalAssetPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // Khi lưu vào Firestore, trường vẫn có thể tên là 'imageUrl'
      'imageUrl': imageAssetPath,
      // if (description != null) 'description': description,
      // 'sortOrder': sortOrder,
    };
  }
  
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'name': name,
      'imageAssetPath': imageAssetPath,
    };
  }
}

