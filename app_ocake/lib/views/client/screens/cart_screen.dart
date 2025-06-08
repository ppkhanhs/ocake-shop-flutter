// app_ocake/views/client/screens/cart_screen.dart

import 'package:app_ocake/views/client/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:app_ocake/models/cart_item.dart';
import 'login_screen.dart';
import 'package:app_ocake/services/database/session_manager.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHomeTab;

  const CartScreen({Key? key, this.onNavigateToHomeTab}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _currentCustomerIdFromSession;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _cartStream;
  List<CartItem> _localCartItems = [];

  // ... (các hàm initState, _loadCartData, didChangeDependencies,
  // _initializeCartStream, _customerCartCollection,
  // updateQuantityOnFirestore, deleteItemFromFirestore,
  // toggleSelection, calculateTotal giữ nguyên) ...

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  void _loadCartData() {
    _currentCustomerIdFromSession = SessionManager.currentCustomerId;
    if (_currentCustomerIdFromSession != null) {
      _initializeCartStream();
    } else {
      if (mounted) {
        setState(() {
          _localCartItems = [];
          _cartStream = null;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newCustomerId = SessionManager.currentCustomerId;
    if (newCustomerId != _currentCustomerIdFromSession) {
      _loadCartData();
    }
  }

  void _initializeCartStream() {
    if (_currentCustomerIdFromSession == null) return;
    _cartStream =
        FirebaseFirestore.instance
            .collection('customers')
            .doc(_currentCustomerIdFromSession!)
            .collection('cartItems')
            .orderBy('addedAt', descending: true)
            .snapshots();
  }

  CollectionReference<Map<String, dynamic>> get _customerCartCollection {
    if (_currentCustomerIdFromSession == null)
      throw Exception("Customer ID not available.");
    return FirebaseFirestore.instance
        .collection('customers')
        .doc(_currentCustomerIdFromSession!)
        .collection('cartItems');
  }

  Future<void> updateQuantityOnFirestore(
    String cartItemId,
    int currentQuantity,
    int change,
  ) async {
    int newQuantity = currentQuantity + change;
    if (newQuantity < 1) newQuantity = 1;
    try {
      await _customerCartCollection.doc(cartItemId).update({
        'quantity': newQuantity,
      });
    } catch (e) {
      print("Error updating quantity: $e");
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật số lượng.')));
    }
  }

  Future<void> deleteItemFromFirestore(String cartItemId) async {
    try {
      await _customerCartCollection.doc(cartItemId).delete();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa sản phẩm khỏi giỏ hàng.')),
        );
    } catch (e) {
      print("Error deleting item: $e");
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa sản phẩm.')));
    }
  }

  void toggleSelection(CartItem itemToToggle) {
    setState(() {
      final index = _localCartItems.indexWhere(
        (item) => item.id == itemToToggle.id,
      );
      if (index != -1) {
        _localCartItems[index].selected = !_localCartItems[index].selected;
      }
    });
  }

  double calculateTotal() {
    return _localCartItems.fold(
      0.0,
      (total, item) =>
          item.selected ? total + (item.price * item.quantity) : total,
    );
  }


  @override
  Widget build(BuildContext context) {
    final customerIdForBuild = SessionManager.currentCustomerId;
    if (customerIdForBuild != _currentCustomerIdFromSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCartData();
      });
      _currentCustomerIdFromSession = customerIdForBuild;
    }

    if (_currentCustomerIdFromSession == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Giỏ hàng'), backgroundColor: Color(0xFFBC132C)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Vui lòng đăng nhập để xem giỏ hàng của bạn.'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text('Đăng nhập'),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFBC132C)),
              ),
            ],
          ),
        ),
      );
    }

    if (_cartStream == null) {
      _initializeCartStream();
      return Scaffold(
        appBar: AppBar(title: Text('Giỏ hàng'), backgroundColor: Color(0xFFBC132C)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Giỏ hàng (${_localCartItems.where((i) => i.selected).length} đã chọn)',
        ),
        backgroundColor: Color(0xFFBC132C),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _cartStream!,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _localCartItems.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("CartScreen Firestore Stream Error: ${snapshot.error}");
                  return Center(child: Text('Lỗi tải giỏ hàng!'));
                }

                if (snapshot.hasData) {
                  List<CartItem> newFirestoreItems =
                      snapshot.data!.docs
                          .map((doc) => CartItem.fromFirestore(doc))
                          .toList();
                  List<CartItem> updatedLocalCartItems = [];
                  for (var newItemFromFirestore in newFirestoreItems) {
                    var existingLocalItem = _localCartItems.firstWhere(
                      (localItem) => localItem.id == newItemFromFirestore.id,
                      orElse: () => newItemFromFirestore,
                    );
                    updatedLocalCartItems.add(
                      CartItem(
                        id: newItemFromFirestore.id,
                        productId: newItemFromFirestore.productId,
                        name: newItemFromFirestore.name,
                        price: newItemFromFirestore.price,
                        quantity: newItemFromFirestore.quantity,
                        imageAssetPath: newItemFromFirestore.imageAssetPath,
                        selected:
                            existingLocalItem.id == newItemFromFirestore.id
                                ? existingLocalItem.selected
                                : newItemFromFirestore.selected,
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted &&
                        !listEquals(_localCartItems, updatedLocalCartItems)) {
                      setState(() {
                        _localCartItems = updatedLocalCartItems;
                      });
                    }
                  });
                }

                if (_localCartItems.isEmpty) {
                  return Center(child: Text('Giỏ hàng của bạn trống.'));
                }

                return ListView.builder(
                  itemCount: _localCartItems.length,
                  itemBuilder: (context, index) {
                    final item = _localCartItems[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        deleteItemFromFirestore(item.id);
                      },
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.delete_sweep_outlined,
                          color: Colors.white,
                        ),
                      ),
                      child: Card(
                        // UI CỦA TỪNG ITEM TRONG GIỎ HÀNG
                        margin: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: item.selected,
                                onChanged: (value) => toggleSelection(item),
                                activeColor: Color(0xFFBC132C),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.asset(
                                  item.imageAssetPath,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (c, e, s) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.broken_image),
                                      ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${item.price.toStringAsFixed(0)}đ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      size: 22,
                                      color:
                                          item.quantity > 1
                                              ? Colors.redAccent
                                              : Colors.grey,
                                    ),
                                    onPressed:
                                        item.quantity > 1
                                            ? () => updateQuantityOnFirestore(
                                              item.id,
                                              item.quantity,
                                              -1,
                                            )
                                            : null,
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      size: 22,
                                      color: Colors.green,
                                    ),
                                    onPressed:
                                        () => updateQuantityOnFirestore(
                                          item.id,
                                          item.quantity,
                                          1,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // ---- PHẦN TỔNG TIỀN VÀ NÚT THANH TOÁN ----
          if (_localCartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng cộng (${_localCartItems.where((i) => i.selected).length} món):',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${calculateTotal().toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBC132C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFBC132C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:
                        _localCartItems.any((item) => item.selected)
                            ? () {
                              List<CartItem> selectedItemsToCheckout =
                                  _localCartItems
                                      .where((item) => item.selected)
                                      .toList();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CheckoutScreen(
                                        checkoutItems: selectedItemsToCheckout,
                                        totalAmount: calculateTotal(),
                                        customerId:
                                            _currentCustomerIdFromSession,
                                        onNavigateToHomeTab: widget.onNavigateToHomeTab, // <-- TRUYỀN CALLBACK VÀO ĐÂY
                                      ),
                                ),
                              );
                            }
                            : null,
                    child: const Text(
                      'Tiến hành thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}