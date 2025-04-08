import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Thêm sản phẩm
  Future<void> addProduct(Map<String, dynamic> productData) async {
    await _db.collection("products").add(productData);
  }

  // Lấy danh sách sản phẩm
  Future<List<Map<String, dynamic>>> getProducts() async {
    var snapshot = await _db.collection("products").get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
