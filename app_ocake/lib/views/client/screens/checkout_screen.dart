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
  bool _isPlacingOrder = false;

  final List<Map<String, dynamic>> _staticPaymentMethodsForFallback = [
    // Giữ lại phòng trường hợp Firestore lỗi
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

    _nameController.text = SessionManager.currentCustomerName ?? '';
    _phoneController.text = SessionManager.currentCustomerPhone ?? '';
    _addressController.text = SessionManager.currentCustomerAddress ?? '';
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
    });
    try {
      QuerySnapshot paymentMethodsSnapshot =
          await FirebaseFirestore.instance
              .collection('paymentMethods')
              .where('isActive', isEqualTo: true)
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
            if (_availablePaymentMethods.isNotEmpty) {
              _selectedPaymentMethod = _availablePaymentMethods.firstWhere(
                (method) => method.id == 'cash',
                orElse: () => _availablePaymentMethods.first,
              );
            }
          });
        }
      } else {
        // Fallback to static list if Firestore is empty or error
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
          SnackBar(
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

  void _useStaticPaymentMethods() {
    if (mounted) {
      setState(() {
        _availablePaymentMethods =
            _staticPaymentMethodsForFallback.map((data) {
              // Tạo tạm DocumentSnapshot giả để dùng chung fromFirestore
              // Hoặc bạn có thể tạo constructor riêng cho PaymentMethod từ Map
              // Đây là cách đơn giản để tái sử dụng fromFirestore
              var fakeDocData = Map<String, dynamic>.from(data);
              fakeDocData.remove(
                'icon',
              ); // fromFirestore không cần icon IconData trực tiếp

              // Tạo một DocumentSnapshot giả
              // Đây là một cách không chính thống, tốt hơn là PaymentMethod có constructor nhận Map
              var fakeSnapshot = _FakeDocumentSnapshot(
                data['value'],
                fakeDocData,
              );

              return PaymentMethod.fromFirestore(fakeSnapshot);
            }).toList();

        if (_availablePaymentMethods.isNotEmpty) {
          _selectedPaymentMethod = _availablePaymentMethods.firstWhere(
            (method) => method.id == 'cash',
            orElse: () => _availablePaymentMethods.first,
          );
        }
      });
    }
  }

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
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Chỉnh sửa thông tin giao hàng'),
          content: SingleChildScrollView(
            child: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tempNameController,
                    decoration: InputDecoration(labelText: 'Họ và tên'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Vui lòng nhập họ tên'
                                : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: tempPhoneController,
                    decoration: InputDecoration(labelText: 'Số điện thoại'),
                    keyboardType: TextInputType.phone,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Vui lòng nhập số điện thoại'
                                : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: tempAddressController,
                    decoration: InputDecoration(labelText: 'Địa chỉ nhận hàng'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Vui lòng nhập địa chỉ'
                                : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              child: Text('Lưu'),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  setState(() {
                    _nameController.text = tempNameController.text;
                    _phoneController.text = tempPhoneController.text;
                    _addressController.text = tempAddressController.text;
                  });
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (widget.checkoutItems.isEmpty) {
      /* ... */
      return;
    }
    if (widget.customerId == null) {
      /* ... */
      return;
    }
    if (_selectedPaymentMethod == null) {
      /* ... */
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    String orderId = 'DH${DateTime.now().millisecondsSinceEpoch}';
    List<Map<String, dynamic>> orderItemsForFirestore =
        widget.checkoutItems.map((item) {
          return {
            'productId': item.productId,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'imageUrl': item.imageAssetPath,
          };
        }).toList();

    Map<String, dynamic> orderData = {
      'orderId': orderId,
      'customerId': widget.customerId,
      'customerName': _nameController.text.trim(),
      'customerPhone': _phoneController.text.trim(),
      'customerAddress': _addressController.text.trim(),
      'paymentMethod': _selectedPaymentMethod!.title,
      'totalAmount': widget.totalAmount,
      'items': orderItemsForFirestore,
      'status': 'Chờ xác nhận',
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(orderData);
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderConfirmationScreen(
                  orderId: orderId,
                  name: _nameController.text,
                  phone: _phoneController.text,
                  address: _addressController.text,
                  paymentMethod: _selectedPaymentMethod!.title,
                  totalAmount: widget.totalAmount,
                  orderedItems: widget.checkoutItems,
                ),
          ),
        );
      }
    } catch (e) {
      /* ... */
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đơn hàng'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
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
                              child: Text(
                                'Sửa',
                                style: TextStyle(color: Colors.green),
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
                          readOnlyStatus: _isPlacingOrder,
                        ),
                        SizedBox(height: 12),
                        _buildInfoTextFormField(
                          _phoneController,
                          'Số điện thoại',
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator:
                              (v) => v!.isEmpty ? 'Vui lòng nhập SĐT' : null,
                          readOnlyStatus: _isPlacingOrder,
                        ),
                        SizedBox(height: 12),
                        _buildInfoTextFormField(
                          _addressController,
                          'Địa chỉ nhận hàng',
                          Icons.home_outlined,
                          maxLines: 2,
                          validator:
                              (v) =>
                                  v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                          readOnlyStatus: _isPlacingOrder,
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: widget.checkoutItems.length,
                          separatorBuilder:
                              (context, index) =>
                                  Divider(height: 16, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final item = widget.checkoutItems[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .spaceBetween, // Căn đều giá ra cuối dòng
                                children: [
                                  Row(
                                    // Bọc ảnh và thông tin text vào Row
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start, // Căn ảnh và text theo top
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
                                                child: Icon(
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
                                            // Giới hạn chiều rộng cho tên sản phẩm
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.45, // Ví dụ, 45% chiều rộng màn hình
                                            child: Text(
                                              item.name,
                                              style: TextStyle(
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
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey[300],
                        ), // Phân cách rõ hơn
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng cộng sản phẩm:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.totalAmount.toStringAsFixed(0)}đ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0,
                                ),
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : (_availablePaymentMethods.isEmpty
                                ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
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
                                          // --- THÊM Lại DÒNG SAU ---
                                          opacity:
                                              _isPlacingOrder
                                                  ? 0.5
                                                  : 1.0, // Làm mờ nếu đang đặt hàng
                                          // --------------------------
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
                                                        ? Colors.green
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
                                                        ? Colors.green
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
                                                        ? null
                                                        : (
                                                          PaymentMethod? value,
                                                        ) {
                                                          setState(() {
                                                            _selectedPaymentMethod =
                                                                value;
                                                          });
                                                        },
                                                activeColor: Colors.green,
                                              ),
                                              onTap:
                                                  _isPlacingOrder
                                                      ? null
                                                      : () {
                                                        setState(() {
                                                          _selectedPaymentMethod =
                                                              method;
                                                        });
                                                      },
                                              selected:
                                                  _selectedPaymentMethod?.id ==
                                                  method.id,
                                              selectedTileColor: Colors.green
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
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      _isPlacingOrder
                          ? null
                          : () {
                            if (_formKey.currentState!.validate()) {
                              if (_selectedPaymentMethod == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Vui lòng chọn phương thức thanh toán.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                barrierDismissible: !_isPlacingOrder,
                                builder: (dialogContext) {
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
                                                ),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            _isPlacingOrder
                                                ? null
                                                : () {
                                                  _placeOrder()
                                                      .then((_) {
                                                        if (mounted &&
                                                            Navigator.canPop(
                                                              dialogContext,
                                                            )) {
                                                          Navigator.pop(
                                                            dialogContext,
                                                          );
                                                        }
                                                      })
                                                      .catchError((error) {
                                                        // Xử lý lỗi ở đây nếu cần, ví dụ đóng dialog và báo lỗi
                                                        print(
                                                          "Lỗi trong _placeOrder, dialog có thể vẫn mở: $error",
                                                        );
                                                        if (mounted &&
                                                            Navigator.canPop(
                                                              dialogContext,
                                                            )) {
                                                          Navigator.pop(
                                                            dialogContext,
                                                          );
                                                        }
                                                      });
                                                },
                                        child:
                                            _isPlacingOrder
                                                ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 3,
                                                      ),
                                                )
                                                : const Text('Đồng ý'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                  child:
                      _isPlacingOrder
                          ? Row(
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

  Widget _buildInfoTextFormField(
    TextEditingController controller,
    String labelText,
    IconData icon, {
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    bool readOnlyStatus = false,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnlyStatus,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: Colors.green, size: 22),
        filled: true,
        fillColor:
            readOnlyStatus
                ? Colors.grey.shade100.withOpacity(0.5)
                : Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
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

  @override
  SnapshotMetadata get metadata => throw UnimplementedError(); // Không dùng

  @override
  dynamic get(Object field) => _data[field]; // Lấy field

  @override
  operator [](Object field) => _data[field]; // Lấy field

  @override
  DocumentReference<Object?> get reference => throw UnimplementedError(); // Không dùng
}
