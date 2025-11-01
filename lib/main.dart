import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'admin_dashboard_page.dart';
import 'forgot_password_page.dart';
import 'reset_password_page.dart';

void main() {
  runApp(const VietLuTravelApp());
}

class VietLuTravelApp extends StatelessWidget {
  const VietLuTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Việt Lữ Travel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: "/login",
      routes: {
        "/login":           (_) => const LoginPage(),
        "/register":        (_) => const RegisterPage(),
        "/forgot-password": (_) => const ForgotPasswordPage(),
        "/reset-password":  (_) => const ResetPasswordPage(),
        "/home":            (_) => const HomePage(),
        "/admin":           (_) => const AdminDashboardPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
