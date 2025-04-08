import 'package:app_ocake/views/client/screens/cart_screen.dart';
import 'package:app_ocake/views/client/screens/checkout_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Media Picker App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CartScreen()
      ); 
  }
}
