import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;
import 'customer.dart';
import 'package:google_sign_in/google_sign_in.dart';

const List<String> scopes = ['email', 'profile'];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool _isVisible = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  GoogleSignInAccount? _currentUser;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isVisible = true);
        _animationController.forward();
      }
    });

    // Lắng nghe sự kiện đăng nhập Google mới
    GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        setState(() {
          _currentUser = event.user;
          _errorMessage = '';
        });
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        setState(() {
          _currentUser = null;
          _errorMessage = '';
        });
      }
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Email không hợp lệ';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    try {
      // Khởi tạo GoogleSignIn với serverClientId (Web client ID của Firebase)
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: "1041495288519-go7sbnfm2c97p0437ku0192jtoke080s.apps.googleusercontent.com",
      );
      // Gọi authenticate() để đăng nhập
      final user = await googleSignIn.authenticate();
      if (user != null) {
        setState(() => _currentUser = user);
        _showSnackBar("Đăng nhập thành công: ${user.displayName}", Colors.green);
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        _showSnackBar("Đăng nhập bị hủy", Colors.orange);
      }
    } catch (e) {
      _showSnackBar("Lỗi Google Sign-In: $e", Colors.red);
    }
  }


  Future<void> login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    try {
      final body = jsonEncode({
        "Email": _email.text.trim(),
        "Password": _password.text,
      });

      // Login Customer
      final customerUrl = Uri.parse("http://127.0.0.1:8000/customers/login");
      final customerRes = await http
          .post(customerUrl, headers: {"Content-Type": "application/json"}, body: body)
          .timeout(const Duration(seconds: 10));

      if (customerRes.statusCode == 200) {
        if (!mounted) return;
        setState(() => loading = false);
        final data = jsonDecode(customerRes.body);
        globals.currentCustomer = Customer.fromJson(data);
        _showSnackBar(data["message"] ?? "Đăng nhập thành công", Colors.green);
        Navigator.pushReplacementNamed(context, "/home");
        return;
      }

      // Login User
      final userUrl = Uri.parse("http://127.0.0.1:8000/users/login");
      final userRes = await http
          .post(userUrl, headers: {"Content-Type": "application/json"}, body: body)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() => loading = false);

      if (userRes.statusCode == 200) {
        final data = jsonDecode(userRes.body);
        _showSnackBar(data["message"] ?? "Đăng nhập thành công", Colors.green);
        switch (data["RoleName"]) {
          case "Admin":
            Navigator.pushReplacementNamed(context, "/admin");
            break;
          case "Staff":
            Navigator.pushReplacementNamed(context, "/staff");
            break;
          default:
            Navigator.pushReplacementNamed(context, "/home");
        }
      } else {
        final data = jsonDecode(userRes.body);
        _showSnackBar(data["detail"] ?? "Sai Email hoặc Mật khẩu", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnackBar("Lỗi kết nối. Vui lòng thử lại sau.", Colors.red);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Nền gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900.withOpacity(0.8),
                  Colors.blue.shade600.withOpacity(0.7),
                  Colors.blue.shade400.withOpacity(0.6),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 40,
                bottom: math.max(40, keyboardHeight + 20),
              ),
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: size.width > 450 ? 450 : size.width * 0.9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.blue.shade100.withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo
                                Container(
                                  height: 120,
                                  width: 120,
                                  decoration: const BoxDecoration(shape: BoxShape.circle),
                                  child: ClipOval(
                                    child: Image.asset("assets/logo3.jpg", height: 120, width: 120, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Tiêu đề
                                Text("Đăng nhập",
                                    style: TextStyle(
                                        fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                const SizedBox(height: 8),
                                Text("Chào mừng bạn quay trở lại!",
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.grey.shade600)),
                                const SizedBox(height: 32),
                                // Email
                                TextFormField(
                                  controller: _email,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    prefixIcon: Icon(Icons.email_outlined, color: Colors.blue.shade600),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Password
                                TextFormField(
                                  controller: _password,
                                  validator: _validatePassword,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => login(),
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                  decoration: InputDecoration(
                                    labelText: "Mật khẩu",
                                    prefixIcon: Icon(Icons.lock_outlined, color: Colors.blue.shade600),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Nút đăng nhập
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: loading
                                      ? const Center(child: CircularProgressIndicator())
                                      : ElevatedButton(
                                    onPressed: login,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      backgroundColor: Colors.blue.shade600,
                                    ),
                                    child: const Text("Đăng nhập"),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Google Sign-In
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    icon: Image.asset('assets/loho.png', height: 24, width: 24),
                                    label: const Text('Đăng nhập với Google', style: TextStyle(color: Colors.black87)),
                                    onPressed: _loginWithGoogle,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Link đăng ký
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, "/register"),
                                  child: const Text("Chưa có tài khoản? Đăng ký ngay"),
                                ),
                                // Link quên mật khẩu
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                      onPressed: () => Navigator.pushNamed(context, "/forgot-password"),
                                      child: const Text("Quên mật khẩu?")),
                                ),
                                const SizedBox(height: 16),
                                Text("© 2025 Trần Bảo Duy. All rights reserved.",
                                    style: TextStyle(color: Colors.blue.withOpacity(0.7))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
