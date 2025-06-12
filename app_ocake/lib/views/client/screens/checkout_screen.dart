// app_ocake/views/client/screens/checkout_screen.dart

import 'package:app_ocake/views/client/screens/checkout_confirm_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_ocake/models/cart_item.dart';
import 'package:app_ocake/models/payment_method.dart';
import 'package:app_ocake/services/database/session_manager.dart';
import 'momo_qr_screen.dart'; // Import MomoQrScreen

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> checkoutItems;
  final double totalAmount;
  final String? customerId;
  final VoidCallback? onNavigateToHomeTab;

  const CheckoutScreen({
    Key? key,
    required this.checkoutItems,
    required this.totalAmount,
    this.customerId,
    this.onNavigateToHomeTab,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvcController = TextEditingController();

  PaymentMethod? _selectedPaymentMethod;
  List<PaymentMethod> _availablePaymentMethods = [];
  bool _isLoadingPaymentMethods = true;
  bool _isPlacingOrder = false;

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
    _nameController.text = SessionManager.currentCustomerName ?? '';
    _phoneController.text = SessionManager.currentCustomerPhone ?? '';
    _addressController.text = SessionManager.currentCustomerAddress ?? '';
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvcController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingPaymentMethods = true;
    });
    try {
      QuerySnapshot paymentMethodsSnapshot = await FirebaseFirestore.instance
          .collection('paymentMethods')
          .orderBy('sortOrder')
          .get();

      if (paymentMethodsSnapshot.docs.isNotEmpty) {
        List<PaymentMethod> loadedMethods = paymentMethodsSnapshot.docs
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
        _useStaticPaymentMethods();
        print("Không có PTTT nào từ Firestore hoặc collection rỗng, sử dụng PTTT tĩnh.");
      }
    } catch (e) {
      print("Lỗi tải phương thức thanh toán: $e. Sử dụng PTTT tĩnh.");
      _useStaticPaymentMethods();
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

  void _useStaticPaymentMethods() {
    if (mounted) {
      setState(() {
        _availablePaymentMethods = _staticPaymentMethodsForFallback.map((data) {
          var fakeDocData = Map<String, dynamic>.from(data);
          fakeDocData.remove('iconName');
          var fakeSnapshot = _FakeDocumentSnapshot(data['value'], fakeDocData);
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
    TextEditingController tempNameController = TextEditingController(text: _nameController.text);
    TextEditingController tempPhoneController = TextEditingController(text: _phoneController.text);
    TextEditingController tempAddressController = TextEditingController(text: _addressController.text);
    final dialogFormKey = GlobalKey<FormState>();

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
                  _buildInfoTextFormField(
                    tempNameController, 'Họ và tên', Icons.person_outline,
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập họ tên' : null,
                    readOnlyStatus: false,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTextFormField(
                    tempPhoneController, 'Số điện thoại', Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                    readOnlyStatus: false,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoTextFormField(
                    tempAddressController, 'Địa chỉ nhận hàng', Icons.home_outlined,
                    maxLines: 2,
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    readOnlyStatus: false,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(child: const Text('Hủy'), onPressed: () => Navigator.pop(dialogContext)),
            ElevatedButton(
              child: const Text('Lưu'),
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

  Widget _buildCardPaymentForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin thẻ ngân hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoTextFormField(
            _cardNumberController, 'Số thẻ', Icons.credit_card,
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty || v.length < 16 ? 'Vui lòng nhập đủ 16 số thẻ' : null,
            readOnlyStatus: _isPlacingOrder,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoTextFormField(
                  _cardExpiryController, 'Ngày hết hạn (MM/YY)', Icons.calendar_today,
                  keyboardType: TextInputType.datetime,
                  validator: (v) => v!.isEmpty || !RegExp(r'^\d{2}\/\d{2}$').hasMatch(v) ? 'MM/YY' : null,
                  readOnlyStatus: _isPlacingOrder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTextFormField(
                  _cardCvcController, 'CVC', Icons.lock,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty || v.length < 3 ? '3-4 số' : null,
                  readOnlyStatus: _isPlacingOrder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _validateCardForm() {
    if (_selectedPaymentMethod?.id == 'card') {
      if (_cardNumberController.text.isEmpty || _cardNumberController.text.length < 16) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số thẻ hợp lệ.')));
        return false;
      }
      if (_cardExpiryController.text.isEmpty || !RegExp(r'^\d{2}\/\d{2}$').hasMatch(_cardExpiryController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập ngày hết hạn hợp lệ (MM/YY).')));
        return false;
      }
      if (_cardCvcController.text.isEmpty || _cardCvcController.text.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập CVC hợp lệ (3-4 số).')));
        return false;
      }
    }
    return true;
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_validateCardForm()) {
      return;
    }

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
      'customerId': widget.customerId,
      'customerInfo': {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      },
      'paymentMethod': _selectedPaymentMethod!.title,
      'totalAmount': widget.totalAmount,
      'items': orderItemsForFirestore,
      'status': 'Chờ xác nhận',
      'orderDate': FieldValue.serverTimestamp(),
      'employeeId': 'NV000',
      'notes': '',
    };

    if (_selectedPaymentMethod?.id == 'card') {
      orderData['cardDetails'] = {
        'cardNumber': _cardNumberController.text.trim(),
        'cardExpiry': _cardExpiryController.text.trim(),
        'cardCvc': _cardCvcController.text.trim(),
      };
    }

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
        if (Navigator.canPop(context) && ModalRoute.of(context)?.settings.name == 'AlertDialog') {
          Navigator.pop(context);
        }

        if (_selectedPaymentMethod?.id == 'momo') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MomoQrScreen(
                totalAmount: widget.totalAmount,
                orderId: orderId,
                // NEW: Truyền các thông tin cần thiết
                name: _nameController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                paymentMethod: _selectedPaymentMethod!.title,
                orderedItems: widget.checkoutItems,
                onNavigateToHomeTab: widget.onNavigateToHomeTab,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(
                orderId: orderId,
                name: _nameController.text,
                phone: _phoneController.text,
                address: _addressController.text,
                paymentMethod: _selectedPaymentMethod!.title,
                totalAmount: widget.totalAmount,
                orderedItems: widget.checkoutItems,
                onNavigateToHomeTab: widget.onNavigateToHomeTab,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Lỗi khi đặt hàng: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt hàng thất bại. Vui lòng thử lại. Lỗi: $e'),
          ),
        );
        if (Navigator.canPop(context) && ModalRoute.of(context)?.settings.name == 'AlertDialog') {
          Navigator.pop(context);
        }
      }
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              const NeverScrollableScrollPhysics(),
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
                                  children: // LỖI Ở ĐÂY
                                      _availablePaymentMethods.map((method) {
                                        final bool isMethodSelected = _selectedPaymentMethod?.id == method.id;
                                        return Opacity(
                                          opacity:
                                              _isPlacingOrder
                                                  ? 0.5
                                                  : 1.0,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color:
                                                    isMethodSelected
                                                        ? Color(0xFFBC132C)
                                                        : Colors.grey.shade300,
                                                width:
                                                    isMethodSelected
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
                                                    isMethodSelected
                                                        ? Color(0xFFBC132C)
                                                        : Colors.grey[700],
                                              ),
                                              title: Text(
                                                method.title,
                                                style: TextStyle(
                                                  fontWeight:
                                                      isMethodSelected
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
                                                            _cardNumberController.clear();
                                                            _cardExpiryController.clear();
                                                            _cardCvcController.clear();
                                                          });
                                                        },
                                                activeColor: Color(0xFFBC132C),
                                              ),
                                              onTap:
                                                  _isPlacingOrder
                                                      ? null
                                                      : () {
                                                        setState(() {
                                                          _selectedPaymentMethod =
                                                              method;
                                                          _cardNumberController.clear();
                                                          _cardExpiryController.clear();
                                                          _cardCvcController.clear();
                                                        });
                                                      },
                                              selected:
                                                  isMethodSelected,
                                              selectedTileColor: Color(0xFFBC132C)
                                                  .withOpacity(0.05),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                )),
                        if (_selectedPaymentMethod?.id == 'card')
                          _buildCardPaymentForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                          ? null
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
                              // NEW: Xác thực form thẻ trước khi hiển thị dialog xác nhận
                              if (!_validateCardForm()) {
                                return;
                              }
                              showDialog(
                                context:
                                    context,
                                barrierDismissible:
                                    !_isPlacingOrder,
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
                                                  _placeOrder().catchError((
                                                    error,
                                                  ) {
                                                    print(
                                                      "Lỗi trong _placeOrder (từ dialog): $error",
                                                    );
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
                                                ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                  child:
                      _isPlacingOrder
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

  Widget _buildInfoTextFormField(
    TextEditingController controller,
    String labelText,
    IconData icon, {
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    bool readOnlyStatus = false,
    int? maxLines = 1,
  }) {
    final InputBorder _noBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );

    final InputBorder _defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    final InputBorder _focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFBC132C), width: 1.5),
    );

    final InputBorder _errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    );

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
        border: readOnlyStatus ? _noBorder : _defaultBorder,
        enabledBorder: readOnlyStatus ? _noBorder : _defaultBorder,
        focusedBorder: readOnlyStatus ? _noBorder : _focusedBorder,
        errorBorder: readOnlyStatus ? _noBorder : _errorBorder,
        focusedErrorBorder: readOnlyStatus ? _noBorder : _focusedErrorBorder,
      ),
    );
  }
}

class _FakeDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  _FakeDocumentSnapshot(this._id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _id;

  @override
  bool get exists => true;

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic get(Object field) => _data[field];

  @override
  operator [](Object field) => _data[field];

  @override
  DocumentReference<Object?> get reference => throw UnimplementedError();
}