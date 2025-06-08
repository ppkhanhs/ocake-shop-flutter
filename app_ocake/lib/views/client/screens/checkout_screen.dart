import 'package:app_ocake/views/client/screens/checkout_confirm_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_ocake/models/cart_item.dart';
import 'package:app_ocake/models/payment_method.dart';
import 'package:app_ocake/services/database/session_manager.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> checkoutItems;
  final double totalAmount;
  final String? customerId;

  const CheckoutScreen({
    Key? key,
    required this.checkoutItems,
    required this.totalAmount,
    this.customerId,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  PaymentMethod? _selectedPaymentMethod;
  List<PaymentMethod> _availablePaymentMethods = [];
  bool _isLoadingPaymentMethods = true;
  bool _isPlacingOrder = false; // Trạng thái khi đang đặt hàng

  // Danh sách phương thức thanh toán tĩnh dự phòng
  final List<Map<String, dynamic>> _staticPaymentMethodsForFallback = [
    {
      'value': 'cash',
      'iconName': 'attach_money',
      'title': 'Tiền mặt',
      'subtitle': 'Thanh toán khi nhận hàng',
      'isActive': true,
      'sortOrder': 1,
    },
    {
      'value': 'card',
      'iconName': 'credit_card',
      'title': 'Ngân hàng',
      'subtitle': 'Thanh toán qua thẻ ngân hàng',
      'isActive': true,
      'sortOrder': 2,
    },
    {
      'value': 'momo',
      'iconName': 'account_balance_wallet',
      'title': 'Ví MoMo',
      'subtitle': 'Thanh toán qua MoMo',
      'isActive': true,
      'sortOrder': 3,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Khởi tạo các trường thông tin từ SessionManager
    _nameController.text = SessionManager.currentCustomerName ?? '';
    _phoneController.text = SessionManager.currentCustomerPhone ?? '';
    _addressController.text = SessionManager.currentCustomerAddress ?? '';

    _loadPaymentMethods(); // Tải phương thức thanh toán
  }

  // Hàm tải phương thức thanh toán từ Firestore
  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
    });
    try {
      QuerySnapshot paymentMethodsSnapshot =
          await FirebaseFirestore.instance
              .collection('paymentMethods')
              .orderBy('sortOrder')
              .get();

      if (paymentMethodsSnapshot.docs.isNotEmpty) {
        List<PaymentMethod> loadedMethods =
            paymentMethodsSnapshot.docs
                .map((doc) => PaymentMethod.fromFirestore(doc))
                .toList();

        if (mounted) {
          setState(() {
            _availablePaymentMethods = loadedMethods;
            // Chọn phương thức thanh toán mặc định là "Tiền mặt" nếu có,
            // nếu không thì chọn phương thức đầu tiên
            if (_availablePaymentMethods.isNotEmpty) {
              _selectedPaymentMethod = _availablePaymentMethods.firstWhere(
                (method) => method.id == 'cash',
                orElse: () => _availablePaymentMethods.first,
              );
            }
          });
        }
      } else {
        // Fallback to static list if Firestore is empty
        _useStaticPaymentMethods();
        print(
          "Không có PTTT nào từ Firestore hoặc collection rỗng, sử dụng PTTT tĩnh.",
        );
      }
    } catch (e) {
      print("Lỗi tải phương thức thanh toán: $e. Sử dụng PTTT tĩnh.");
      _useStaticPaymentMethods(); // Sử dụng PTTT tĩnh nếu có lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi tải PTTT. Đang sử dụng danh sách dự phòng.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPaymentMethods = false;
        });
      }
    }
  }

  // Hàm sử dụng phương thức thanh toán tĩnh khi có lỗi hoặc không có dữ liệu từ Firestore
  void _useStaticPaymentMethods() {
    if (mounted) {
      setState(() {
        _availablePaymentMethods =
            _staticPaymentMethodsForFallback.map((data) {
              // Tạo một DocumentSnapshot giả để có thể sử dụng PaymentMethod.fromFirestore
              // Đây là một cách không chính thống, tốt hơn là PaymentMethod có constructor nhận Map
              var fakeDocData = Map<String, dynamic>.from(data);
              // Loại bỏ 'iconName' vì fromFirestore không cần IconData trực tiếp
              fakeDocData.remove('iconName');

              var fakeSnapshot = _FakeDocumentSnapshot(
                data['value'],
                fakeDocData,
              );
              return PaymentMethod.fromFirestore(fakeSnapshot);
            }).toList();

        // Chọn phương thức thanh toán mặc định
        if (_availablePaymentMethods.isNotEmpty) {
          _selectedPaymentMethod = _availablePaymentMethods.firstWhere(
            (method) => method.id == 'cash',
            orElse: () => _availablePaymentMethods.first,
          );
        }
      });
    }
  }

  // Hàm hiển thị dialog chỉnh sửa thông tin giao hàng
  void _showEditDialog() {
    TextEditingController tempNameController = TextEditingController(
      text: _nameController.text,
    );
    TextEditingController tempPhoneController = TextEditingController(
      text: _phoneController.text,
    );
    TextEditingController tempAddressController = TextEditingController(
      text: _addressController.text,
    );
    final dialogFormKey =
        GlobalKey<FormState>(); // Key riêng cho form trong dialog

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin giao hàng'),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SỬ DỤNG HÀM HELPER _buildInfoTextFormField Ở ĐÂY
                  _buildInfoTextFormField(
                    tempNameController,
                    'Họ và tên',
                    Icons.person_outline,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Vui lòng nhập họ tên'
                                : null,
                    readOnlyStatus: false, // CHO PHÉP CHỈNH SỬA VÀ HIỂN THỊ VIỀN
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTextFormField(
                    tempPhoneController,
                    'Số điện thoại',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Vui lòng nhập số điện thoại'
                                : null,
                    readOnlyStatus: false, // CHO PHÉP CHỈNH SỬA VÀ HIỂN THỊ VIỀN
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTextFormField(
                    tempAddressController,
                    'Địa chỉ nhận hàng',
                    Icons.home_outlined,
                    maxLines: 2,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Vui lòng nhập địa chỉ'
                                : null,
                    readOnlyStatus: false, // CHO PHÉP CHỈNH SỬA VÀ HIỂN THỊ VIỀN
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(dialogContext), // Đóng dialog
            ),
            ElevatedButton(
              child: const Text('Lưu'),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  setState(() {
                    _nameController.text = tempNameController.text;
                    _phoneController.text = tempPhoneController.text;
                    _addressController.text = tempAddressController.text;
                  });
                  Navigator.pop(dialogContext); // Đóng dialog sau khi lưu
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Hàm đặt đơn hàng (gửi dữ liệu lên Firestore và điều hướng)
  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus(); // Ẩn bàn phím nếu đang hiển thị

    // Kiểm tra validation của form chính
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra các điều kiện cần thiết trước khi đặt hàng
    if (widget.checkoutItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng trống! Không thể đặt hàng.')),
      );
      return;
    }
    if (widget.customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lỗi: Không tìm thấy ID khách hàng. Vui lòng đăng nhập lại.',
          ),
        ),
      );
      return;
    }
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phương thức thanh toán.')),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true; // Bắt đầu trạng thái đang đặt hàng
    });

    // Tạo orderId theo cấu trúc DH + timestamp
    String orderId = 'DH${DateTime.now().millisecondsSinceEpoch}';

    // Chuẩn bị danh sách sản phẩm để lưu vào Firestore
    List<Map<String, dynamic>> orderItemsForFirestore =
        widget.checkoutItems.map((item) {
          return {
            'productId': item.productId,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'imageUrl':
                item.imageAssetPath, // Đảm bảo trường này có trong CartItem model
          };
        }).toList();

    // Dữ liệu đơn hàng để lưu vào Firestore
    Map<String, dynamic> orderData = {
      'customerId': widget.customerId,
      'customerInfo': {
        // Lưu thông tin khách hàng dưới dạng map lồng nhau
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      },
      'paymentMethod': _selectedPaymentMethod!.title,
      'totalAmount': widget.totalAmount,
      'items': orderItemsForFirestore,
      'status': 'Chờ xác nhận',
      'orderDate':
          FieldValue.serverTimestamp(), // Sử dụng FieldValue.serverTimestamp() cho thời gian chính xác
      'employeeId':
          'NV000', // Ví dụ: ID nhân viên mặc định hoặc lấy từ session/admin
      'notes': '', // Trường ghi chú
    };

    try {
      // Lưu đơn hàng vào collection 'orders' với orderId làm document ID
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderData);

      // Xóa các sản phẩm khỏi giỏ hàng của khách hàng (sử dụng WriteBatch để hiệu quả hơn)
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var item in widget.checkoutItems) {
        DocumentReference cartItemRef = FirebaseFirestore.instance
            .collection('customers')
            .doc(widget.customerId!)
            .collection('cartItems')
            .doc(item.id);
        batch.delete(cartItemRef);
      }
      await batch.commit();

      if (mounted) {
        // RẤT QUAN TRỌNG: Đóng AlertDialog xác nhận trước khi điều hướng
        // `context` ở đây là context của _CheckoutScreenState, nhưng khi _placeOrder
        // được gọi từ onPressed của Elevated Button trong AlertDialog, `context`
        // có thể được hiểu là context của cái nút đó, giúp pop chính cái AlertDialog.
        // Dù sao, `Navigator.pop(context)` ở đây là chính xác.
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Đóng AlertDialog xác nhận
        }

        // Điều hướng đến màn hình xác nhận đơn hàng và thay thế màn hình hiện tại
        // Điều này ngăn người dùng quay lại màn hình checkout bằng nút back
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderConfirmationScreen(
                  orderId: orderId, // Truyền ID đơn hàng
                  name: _nameController.text, // Truyền tên khách hàng
                  phone: _phoneController.text, // Truyền số điện thoại
                  address: _addressController.text, // Truyền địa chỉ
                  paymentMethod:
                      _selectedPaymentMethod!
                          .title, // Truyền phương thức thanh toán
                  totalAmount: widget.totalAmount, // Truyền tổng tiền
                  orderedItems:
                      widget.checkoutItems, // Truyền danh sách sản phẩm đã đặt
                ),
          ),
        );
      }
    } catch (e) {
      print("Lỗi khi đặt hàng: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt hàng thất bại. Vui lòng thử lại. Lỗi: $e'),
          ),
        );
        // Đảm bảo đóng dialog nếu có lỗi xảy ra
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false; // Kết thúc trạng thái đang đặt hàng
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đơn hàng'),
        backgroundColor: Color(0xFFBC132C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: 100,
              ), // Khoảng trống cho nút dưới cùng
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Thông tin giao hàng ---
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Thông tin giao hàng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  _isPlacingOrder ? null : _showEditDialog,
                              child: const Text(
                                'Sửa',
                                style: TextStyle(color: Color(0xFFBC132C)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoTextFormField(
                          _nameController,
                          'Họ và tên',
                          Icons.person_outline,
                          validator:
                              (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                          readOnlyStatus: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTextFormField(
                          _phoneController,
                          'Số điện thoại',
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator:
                              (v) => v!.isEmpty ? 'Vui lòng nhập SĐT' : null,
                          readOnlyStatus: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTextFormField(
                          _addressController,
                          'Địa chỉ nhận hàng',
                          Icons.home_outlined,
                          maxLines: 2,
                          validator:
                              (v) =>
                                  v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                          readOnlyStatus: true,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 8, color: Colors.grey[100]),

                  // --- Chi tiết sản phẩm ---
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết sản phẩm (${widget.checkoutItems.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Không cuộn ListView riêng
                          itemCount: widget.checkoutItems.length,
                          separatorBuilder:
                              (context, index) =>
                                  const Divider(height: 16, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final item = widget.checkoutItems[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          item.imageAssetPath,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (c, e, s) => Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 30,
                                                ),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.45,
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'SL: ${item.quantity}',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Giá của từng item
                                  Text(
                                    '${(item.price * item.quantity).toStringAsFixed(0)}đ',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng sản phẩm:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.totalAmount.toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBC132C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 8, color: Colors.grey[100]),

                  // --- Chọn phương thức thanh toán ---
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chọn phương thức thanh toán',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isLoadingPaymentMethods
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : (_availablePaymentMethods.isEmpty
                                ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 20.0,
                                    ),
                                    child: Text(
                                      'Hiện không có phương thức thanh toán khả dụng.',
                                    ),
                                  ),
                                )
                                : Column(
                                  children:
                                      _availablePaymentMethods.map((method) {
                                        return Opacity(
                                          opacity:
                                              _isPlacingOrder
                                                  ? 0.5
                                                  : 1.0, // Làm mờ nếu đang đặt hàng
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color:
                                                    _selectedPaymentMethod
                                                                ?.id ==
                                                            method.id
                                                        ? Color(0xFFBC132C)
                                                        : Colors.grey.shade300,
                                                width:
                                                    _selectedPaymentMethod
                                                                ?.id ==
                                                            method.id
                                                        ? 1.5
                                                        : 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              leading: Icon(
                                                method.icon,
                                                color:
                                                    _selectedPaymentMethod
                                                                ?.id ==
                                                            method.id
                                                        ? Color(0xFFBC132C)
                                                        : Colors.grey[700],
                                              ),
                                              title: Text(
                                                method.title,
                                                style: TextStyle(
                                                  fontWeight:
                                                      _selectedPaymentMethod
                                                                  ?.id ==
                                                              method.id
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                              ),
                                              subtitle: Text(method.subtitle),
                                              trailing: Radio<PaymentMethod>(
                                                value: method,
                                                groupValue:
                                                    _selectedPaymentMethod,
                                                onChanged:
                                                    _isPlacingOrder
                                                        ? null // Không cho phép chọn khi đang đặt hàng
                                                        : (
                                                          PaymentMethod? value,
                                                        ) {
                                                          setState(() {
                                                            _selectedPaymentMethod =
                                                                value;
                                                          });
                                                        },
                                                activeColor: Color(0xFFBC132C),
                                              ),
                                              onTap:
                                                  _isPlacingOrder
                                                      ? null // Không cho phép chọn khi đang đặt hàng
                                                      : () {
                                                        setState(() {
                                                          _selectedPaymentMethod =
                                                              method;
                                                        });
                                                      },
                                              selected:
                                                  _selectedPaymentMethod?.id ==
                                                  method.id,
                                              selectedTileColor: Color(0xFFBC132C)
                                                  .withOpacity(0.05),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --- Nút Đặt đơn hàng ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFBC132C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      _isPlacingOrder
                          ? null // Vô hiệu hóa nút nếu đang xử lý
                          : () {
                            if (_formKey.currentState!.validate()) {
                              if (_selectedPaymentMethod == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vui lòng chọn phương thức thanh toán.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              showDialog(
                                context:
                                    context, // Context của màn hình CheckoutScreen
                                barrierDismissible:
                                    !_isPlacingOrder, // Không cho phép đóng bằng cách chạm ra ngoài khi đang xử lý
                                builder: (dialogContext) {
                                  // Context của AlertDialog
                                  return AlertDialog(
                                    title: const Text('Xác nhận đặt hàng'),
                                    content: const Text(
                                      'Bạn có chắc muốn đặt đơn hàng này không?',
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text('Hủy'),
                                        onPressed:
                                            _isPlacingOrder
                                                ? null
                                                : () => Navigator.pop(
                                                  dialogContext,
                                                ), // Đóng dialog bằng dialogContext
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            _isPlacingOrder
                                                ? null // Vô hiệu hóa nút nếu đang xử lý
                                                : () {
                                                  // Gọi hàm _placeOrder để xử lý logic và điều hướng
                                                  // _placeOrder đã được chỉnh sửa để tự đóng dialog và pushReplacement
                                                  _placeOrder().catchError((
                                                    error,
                                                  ) {
                                                    print(
                                                      "Lỗi trong _placeOrder (từ dialog): $error",
                                                    );
                                                    // Xử lý lỗi nếu cần, ví dụ: hiển thị SnackBar
                                                  });
                                                },
                                        child:
                                            _isPlacingOrder
                                                ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 3,
                                                      ),
                                                )
                                                : const Text(
                                                  'Đồng ý',
                                                ), // Văn bản nút
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                  child:
                      _isPlacingOrder // Hiển thị loading spinner hoặc văn bản
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Đang xử lý...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            'Đặt đơn hàng',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper để tạo các TextFormField thông tin
  Widget _buildInfoTextFormField(
    TextEditingController controller,
    String labelText,
    IconData icon, {
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    bool readOnlyStatus = false,
    int? maxLines = 1,
  }) {
    // Định nghĩa viền không có gì (transparent)
    final InputBorder _noBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none, // Loại bỏ hoàn toàn viền
    );

    // Định nghĩa viền mặc định khi không phải readOnly
    final InputBorder _defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    // Định nghĩa viền khi được focus (không phải readOnly)
    final InputBorder _focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFBC132C), width: 1.5),
    );

    // Định nghĩa viền khi có lỗi (không phải readOnly)
    final InputBorder _errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    );

    // Định nghĩa viền khi có lỗi và được focus (không phải readOnly)
    final InputBorder _focusedErrorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnlyStatus,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Color(0xFFBC132C), size: 22),
        filled: true,
        fillColor:
            readOnlyStatus
                ? Colors.grey.shade100.withOpacity(0.5)
                : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        // Áp dụng các loại viền dựa trên trạng thái readOnlyStatus
        // Nếu readOnlyStatus là true, tất cả các viền sẽ là _noBorder
        border: readOnlyStatus ? _noBorder : _defaultBorder,
        enabledBorder: readOnlyStatus ? _noBorder : _defaultBorder,
        focusedBorder: readOnlyStatus ? _noBorder : _focusedBorder,
        errorBorder: readOnlyStatus ? _noBorder : _errorBorder,
        focusedErrorBorder: readOnlyStatus ? _noBorder : _focusedErrorBorder,
      ),
    );
  }
}

// Lớp giả lập DocumentSnapshot chỉ để dùng với _useStaticPaymentMethods
// Không cần thiết nếu bạn đảm bảo collection 'paymentMethods' trên Firestore luôn có dữ liệu
class _FakeDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  _FakeDocumentSnapshot(this._id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _id;

  @override
  bool get exists => true; // Luôn giả sử tồn tại

  // Các phương thức không dùng đến, chỉ cần throw UnimplementedError
  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic get(Object field) => _data[field];

  @override
  operator [](Object field) => _data[field];

  @override
  DocumentReference<Object?> get reference => throw UnimplementedError();
}
