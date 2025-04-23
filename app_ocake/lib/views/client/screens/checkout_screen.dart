import 'package:app_ocake/views/client/screens/checkout_confirm_screen.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  TextEditingController _nameController =
      TextEditingController(text: 'Khanh');
  TextEditingController _phoneController =
      TextEditingController(text: '0327749747');
  TextEditingController _addressController =
      TextEditingController(text: '140 Le Trong Tan, HCM');

  String _selectedPayment = 'cash';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'value': 'cash',
      'icon': Icons.attach_money,
      'title': 'Tiền mặt',
      'subtitle': 'Thanh toán khi nhận hàng',
    },
    {
      'value': 'card',
      'icon': Icons.credit_card,
      'title': 'Ngân hàng',
      'subtitle': 'Thanh toán qua thẻ ngân hàng',
    },
    {
      'value': 'momo',
      'icon': Icons.account_balance_wallet,
      'title': 'Ví MoMo',
      'subtitle': 'Thanh toán qua MoMo',
    },
  ];

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chỉnh sửa thông tin'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Họ và tên'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Địa chỉ nhận hàng'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Lưu'),
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đơn hàng',),
        backgroundColor: Colors.green),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn chỉnh hai bên
                        children: [
                          const Text(
                            'Thông tin',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: _showEditDialog,
                            child: const Text('Sửa'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Họ tên: ${_nameController.text}'),
                      Text('Số điện thoại: ${_phoneController.text}'),
                      Text('Địa chỉ: ${_addressController.text}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi tiết sản phẩm',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/cake.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bánh bông lan dâu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dâu tươi',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        '49.000đ',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        'x1',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn phương thức thanh toán',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: _paymentMethods.map((method) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPayment == method['value']
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(method['icon'], color: Colors.green),
                              title: Text(method['title']),
                              subtitle: Text(method['subtitle']),
                              trailing: Radio<String>(
                                value: method['value'],
                                groupValue: _selectedPayment,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPayment = value!;
                                  });
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedPayment = method['value'];
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
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
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  String orderId = 'DH${DateTime.now().millisecondsSinceEpoch}';

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Xác nhận đặt hàng'),
                        content: const Text('Bạn có chắc muốn đặt đơn hàng này không?'),
                        actions: [
                          TextButton(
                            child: const Text('Hủy'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            child: const Text('Đồng ý'),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderConfirmationScreen(
                                    orderId: orderId,
                                    name: _nameController.text,
                                    phone: _phoneController.text,
                                    address: _addressController.text,
                                    paymentMethod: _paymentMethods.firstWhere(
                                      (m) => m['value'] == _selectedPayment,
                                    )['title'],
                                    totalAmount: 400000,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Đặt đơn hàng',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
