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
    // (Tùy chọn) Bạn có thể thêm logic ở đây để quyết định màn hình ban đầu
    // dựa trên trạng thái đăng nhập từ UserProvider, ví dụ:
    // final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Widget initialScreen = userProvider.userId != null ? HomeScreen() : LoginScreen();

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
      // home: initialScreen, // Nếu bạn có logic kiểm tra initialScreen ở trên
      home: LoginScreen(), // Bắt đầu với màn hình đăng nhập
      // Hoặc LoginScreenCustom() nếu bạn đã đổi tên
      debugShowCheckedModeBanner: false, // Tắt banner debug
      // (Tùy chọn) Định nghĩa các routes nếu bạn muốn sử dụng điều hướng bằng tên
      // routes: {
      //   '/login': (context) => LoginScreen(), // Hoặc LoginScreenCustom()
      //   '/home': (context) => HomeScreen(),
      //   '/register': (context) => RegisterScreen(), // Hoặc RegisterScreenCustomForCustomers()
      //   // ... các routes khác
      // },
      // initialRoute: '/login', // Nếu dùng named routes, đặt route ban đầu
    );
  }
}
