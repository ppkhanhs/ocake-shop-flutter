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
      TextEditingController(text: '+1234567890');
  TextEditingController _addressController =
      TextEditingController(text: '104 Le Trong Tan, HCM');

  String _selectedPayment = 'cash';
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'value': 'cash',
      'icon': Icons.attach_money,
      'title': 'Thanh toán khi nhận hàng',
      'subtitle': 'Cash on Delivery',
    },
    {
      'value': 'card',
      'icon': Icons.credit_card,
      'title': 'Thẻ ngân hàng',
      'subtitle': 'Credit / Debit Card',
    },
    {
      'value': 'ewallet',
      'icon': Icons.account_balance_wallet,
      'title': 'Ví điện tử',
      'subtitle': 'ZaloPay, Momo...',
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
                  decoration: InputDecoration(labelText: 'Tên'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Địa chỉ'),
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
                setState(() {}); // Cập nhật UI
                Navigator.pop(context); // Đóng hộp thoại
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
        title: Text('Hoàn tất đơn hàng'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thông tin người dùng
            Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Name: ${_nameController.text}'),
                  Text('Phone: ${_phoneController.text}'),
                  Text('Address: ${_addressController.text}'),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showEditDialog,
                      child: Text('Edit'),
                    ),
                  ),
                ],
              ),
            ),

            // Chi tiết sản phẩm
            Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết sản phẩm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
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
                            'assets/images/cake-1.jpg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bánh bông lan dâu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Dâu tươi',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '49.000đ',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  Text(
                                    'x1',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
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

            // Phương thức thanh toán
            Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phương thức thanh toán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Column(
                    children: _paymentMethods.map((method) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedPayment == method['value']
                                ? Colors.blue
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(method['icon'], color: Colors.blue),
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
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        String orderId = 'DH${DateTime.now().millisecondsSinceEpoch}';

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Xác nhận đặt hàng'),
                              content: Text('Bạn có chắc muốn đặt đơn hàng này không?'),
                              actions: [
                                TextButton(
                                  child: Text('Hủy'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                ElevatedButton(
                                  child: Text('Đồng ý'),
                                  onPressed: () {
                                    Navigator.pop(context); // đóng AlertDialog trước
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
                                          totalAmount: 400000, // hoặc tổng tiền thật
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
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'XÁC NHẬN ĐƠN HÀNG',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
