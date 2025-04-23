import 'package:app_ocake/views/client/screens/profile_screen.dart';
import 'package:app_ocake/views/admin/screens/manage_products_screen.dart';
import 'package:app_ocake/views/client/screens/home_screen.dart';
import 'package:app_ocake/views/client/screens/login_screen.dart';
import 'package:app_ocake/views/client/screens/register_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hỷ Lâm Môn',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Roboto'),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
