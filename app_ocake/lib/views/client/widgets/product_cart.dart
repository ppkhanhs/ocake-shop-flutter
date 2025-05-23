// lib/widgets/product_cart.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Cho FieldValue
// --- SỬA LẠI ĐƯỜNG DẪN IMPORT CHO ĐÚNG VỚI DỰ ÁN CỦA BẠN ---
import 'package:app_ocake/models/product.dart';
// Giả sử SessionManager được dùng để lấy customerId
import 'package:app_ocake/services/database/session_manager.dart';
// -------------------------------------------------------------

class ProductCart extends StatelessWidget {
  final Product product;
  final VoidCallback
  onTap; // Callback khi nhấn vào toàn bộ card (để xem chi tiết)

  const ProductCart({Key? key, required this.product, required this.onTap})
    : super(key: key);

  // --- PHƯƠNG THỨC THÊM VÀO GIỎ HÀNG (BÊN TRONG CLASS ProductCart) ---
  // Logic này nên được đặt trong một CartService để tái sử dụng và dễ quản lý hơn,
  // nhưng để đơn giản, ta đặt tạm ở đây.
  Future<void> _handleAddToCart(BuildContext context, int quantityToAdd) async {
    String? customerId = SessionManager.currentCustomerId;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng.'),
        ),
      );
      // TODO: Có thể điều hướng người dùng đến màn hình đăng nhập
      return;
    }

    if (quantityToAdd < 1) return; // Số lượng không hợp lệ

    // Dùng product.id làm Document ID cho cartItem để dễ kiểm tra tồn tại và cập nhật
    final DocumentReference cartItemRef = FirebaseFirestore.instance
        .collection('customers') // Collection lưu thông tin khách hàng
        .doc(customerId) // Document của khách hàng hiện tại
        .collection('cartItems') // Sub-collection giỏ hàng của khách hàng đó
        .doc(product.id); // Dùng ID sản phẩm làm ID cho item trong giỏ

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(cartItemRef);
        int newQuantity = quantityToAdd;

        if (snapshot.exists) {
          // Sản phẩm đã có trong giỏ, cập nhật số lượng
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          newQuantity = (data['quantity'] as int? ?? 0) + quantityToAdd;
        }

        // Luôn sử dụng displayPrice (giá đã bao gồm khuyến mãi nếu có) khi thêm vào giỏ
        Map<String, dynamic> dataToSet = {
          'productId': product.id,
          'name': product.name,
          'price':
              product.displayPrice, // <-- LƯU GIÁ HIỂN THỊ (ĐÃ GIẢM NẾU CÓ)
          'quantity': newQuantity,
          'imageUrl': product.imageAssetPath, // Đường dẫn asset
          'addedAt': FieldValue.serverTimestamp(), // Thời gian thêm/cập nhật
        };

        if (snapshot.exists) {
          // Chỉ cập nhật quantity, price và addedAt nếu sản phẩm đã tồn tại
          transaction.update(cartItemRef, {
            'quantity': newQuantity,
            'price':
                dataToSet['price'], // Cập nhật giá phòng trường hợp giá gốc/khuyến mãi thay đổi
            'addedAt': dataToSet['addedAt'],
          });
        } else {
          // Nếu chưa tồn tại, set toàn bộ dữ liệu
          transaction.set(cartItemRef, dataToSet);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${product.name} vào giỏ hàng!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print("Lỗi khi thêm ${product.name} vào giỏ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thêm vào giỏ. Vui lòng thử lại.')),
      );
    }
  }
  // -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Lấy các giá trị từ getter của model Product
    bool isActuallyAvailable =
        product.isAvailable ?? true; // Mặc định là true nếu null
    double displayPriceToShow =
        product.displayPrice; // Giá sẽ hiển thị (đã tính discount)
    double? originalPriceToShow =
        product.originalPriceForDisplay; // Giá gốc (nếu có discount)

    return Opacity(
      opacity: isActuallyAvailable ? 1.0 : 0.5, // Giảm opacity nếu hết hàng
      child: Card(
        elevation: 2.5, // Giảm nhẹ elevation
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ), // Bo tròn ít hơn một chút
        child: InkWell(
          onTap:
              isActuallyAvailable
                  ? onTap
                  : null, // Chuyển đến chi tiết sản phẩm
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hình ảnh sản phẩm và các Tag (Giảm giá, Hết hàng, Bán chạy)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 11, // Tỉ lệ ảnh có thể điều chỉnh
                    child: Hero(
                      tag:
                          'product_image_${product.id}', // Tag cho Hero Animation
                      child: Image.asset(
                        product.imageAssetPath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.bakery_dining_outlined,
                              color: Colors.grey[400],
                              size: 40,
                            ), // Icon placeholder
                          );
                        },
                      ),
                    ),
                  ),
                  // Tag "Giảm giá"
                  if (originalPriceToShow != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'GIẢM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Tag "Bán chạy"
                  if (product.isBestSeller == true)
                    Positioned(
                      top:
                          (originalPriceToShow != null)
                              ? 26
                              : 6, // Vị trí tùy thuộc có tag Giảm giá không
                      left: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'BÁN CHẠY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Thông báo "Hết hàng"
                  if (!isActuallyAvailable)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                            0.6,
                          ), // Lớp phủ mờ hơn
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'HẾT HÀNG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Nội dung (Tên, Giá)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    8.0,
                    10.0,
                    4.0,
                  ), // Giảm padding bottom
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Tên và giá gần nhau hơn
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child:
                            originalPriceToShow != null
                                ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${originalPriceToShow.toStringAsFixed(0)}đ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '${displayPriceToShow.toStringAsFixed(0)}đ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                                : Text(
                                  '${displayPriceToShow.toStringAsFixed(0)}đ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).primaryColorDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nút thêm vào giỏ hàng - Đặt ở cuối cùng của Column
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  4,
                  0,
                  4,
                  4,
                ), // Padding cho nút
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    iconSize: 24,
                    splashRadius: 22,
                    padding:
                        EdgeInsets.zero, // Bỏ padding mặc định của IconButton
                    constraints: BoxConstraints(), // Bỏ contraints mặc định
                    icon: Container(
                      // Bọc Icon trong Container để tạo nền tròn
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color:
                            isActuallyAvailable
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        boxShadow:
                            isActuallyAvailable
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                                : null,
                      ),
                      child: Icon(
                        isActuallyAvailable
                            ? Icons.add_shopping_cart_rounded
                            : Icons.remove_shopping_cart_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    tooltip:
                        isActuallyAvailable
                            ? 'Thêm vào giỏ'
                            : 'Sản phẩm đã hết hàng',
                    onPressed:
                        isActuallyAvailable
                            ? () => _handleAddToCart(
                              context,
                              1,
                            ) // Mặc định thêm 1 sản phẩm
                            : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
