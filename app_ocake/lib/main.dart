// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'views/client/screens/login_screen.dart';
import 'views/client/screens/home_screen.dart';
import 'views/client/screens/register_screen.dart';
// -------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Đảm bảo Flutter bindings đã sẵn sàng
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions
            .currentPlatform, // Sử dụng cấu hình Firebase tự động
  );

  runApp(
    // 3. Bọc ứng dụng của bạn bằng ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => UserProvider(), // Tạo một instance của UserProvider
      child: MainApp(), // Widget gốc của ứng dụng
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hỷ Lâm Môn', // Tên ứng dụng của bạn
      theme: ThemeData(
        primaryColor: Color(0xFFBC132C), // Màu chủ đạo
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFFBC132C),
          secondary: Color(0xFFBC132C),
        ),
        fontFamily: 'Roboto', // Font chữ mặc định (nếu có)
        // (Tùy chọn) Tùy chỉnh thêm theme ở đây
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFBC132C), // Màu nút ElevatedButton
            foregroundColor: Colors.white, // Màu chữ trên nút
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFBC132C),
          foregroundColor: Colors.white, // Màu chữ và icon trên AppBar
          elevation: 1,
        ),
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
