import 'package:flutter/material.dart';
import 'package:app_ocake/models/cake.dart';

class CakeCard extends StatelessWidget {
  // --- THAY ĐỔI: Nhận vào một đối tượng Cake ---
  final Cake cake;
  final VoidCallback onTap; // Giữ lại onTap nếu bạn xử lý click ở widget cha

  const CakeCard({
    Key? key, // Thêm Key cho widget
    required this.cake, // Tham số mới
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double displayPrice = cake.price;
    double? originalPriceForDisplay; // Để hiển thị giá gốc bị gạch đi (nếu có)

    if (cake.discountPrice != null &&
        cake.discountPrice! > 0 &&
        cake.discountPrice! < cake.price) {
      displayPrice = cake.discountPrice!;
      originalPriceForDisplay = cake.price;
    }

    return InkWell(
      onTap: onTap, // Sử dụng onTap được truyền vào
      child: Card(
        elevation: 3, // Giảm nhẹ elevation
        clipBehavior: Clip.antiAlias, // Giúp bo tròn ảnh tốt hơn
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), // Bo tròn ít hơn
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh bánh
            AspectRatio(
              // Giữ tỉ lệ ảnh
              aspectRatio:
                  16 / 11, // Điều chỉnh tỉ lệ ảnh nếu cần (width / height)
              child: Hero(
                // Thêm Hero để có hiệu ứng chuyển cảnh đẹp
                tag: 'cake_image_${cake.id}', // Tag duy nhất cho Hero animation
                child: Image.asset(
                  cake.imageAssetPath, // Sử dụng đường dẫn asset từ đối tượng Cake
                  // height: 100, // AspectRatio sẽ quản lý chiều cao
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print(
                      "!!! CakeCard Asset Image Error for ${cake.name} (Path: ${cake.imageAssetPath}): $error",
                    );
                    return Container(
                      // height: 100, // AspectRatio quản lý
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Nội dung (Tên, Giá, Nút)
            Expanded(
              // Cho phép phần này co giãn để đẩy nút thêm vào giỏ xuống dưới
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween, // Đẩy các item con ra xa nhau
                  children: [
                    // Tên bánh
                    Text(
                      cake.name, // Lấy tên từ đối tượng Cake
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5, // Điều chỉnh kích thước font
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 4), // Khoảng cách nhỏ
                    // Giá bánh
                    FittedBox(
                      // Đảm bảo giá không bị tràn nếu quá dài
                      fit: BoxFit.scaleDown,
                      child:
                          originalPriceForDisplay != null
                              ? Row(
                                // Hiển thị cả giá gốc và giá giảm
                                crossAxisAlignment:
                                    CrossAxisAlignment.end, // Căn theo baseline
                                children: [
                                  Text(
                                    '${originalPriceForDisplay.toStringAsFixed(0)}đ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    '${displayPrice.toStringAsFixed(0)}đ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color:
                                          Theme.of(
                                            context,
                                          ).primaryColor, // Dùng màu chủ đạo
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                              : Text(
                                // Chỉ hiển thị giá thường
                                '${displayPrice.toStringAsFixed(0)}đ',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),

            // Nút thêm vào giỏ hàng
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: EdgeInsets.only(right: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor, // Hoặc màu bạn muốn
                  borderRadius: BorderRadius.circular(20), // Bo tròn hơn
                  boxShadow: [
                    // Thêm đổ bóng nhẹ cho đẹp hơn
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.all(6), // Tăng padding cho dễ nhấn
                  constraints:
                      BoxConstraints(), // Bỏ giới hạn kích thước mặc định
                  icon: Icon(
                    Icons.add_shopping_cart_outlined,
                    color: Colors.white,
                    size: 20,
                  ), // Đổi icon
                  tooltip: 'Thêm vào giỏ', // Thêm tooltip cho dễ hiểu
                  onPressed: () {
                    // TODO: Xử lý logic thêm vào giỏ hàng thực tế ở đây
                    // Ví dụ: context.read<CartProvider>().addItem(cake);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm ${cake.name} vào giỏ hàng'),
                        duration: Duration(
                          seconds: 1,
                        ), // Giảm thời gian hiển thị
                        backgroundColor: Colors.green[700], // Màu nền SnackBar
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
