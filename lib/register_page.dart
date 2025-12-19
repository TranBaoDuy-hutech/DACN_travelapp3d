import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui'; // Dùng cho BackdropFilter
import 'dart:math' as math;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool loading = false;
  bool _isVisible = false;
  bool _obscurePassword = true;
  double _buttonScale = 1.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
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
  }

  String? _validateUserName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập tên người dùng';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (!RegExp(r'^\+?\d{10,12}$').hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final url = Uri.parse("http://127.0.0.1:8000/customers/register");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "UserName": _userName.text.trim(),
          "Email": _email.text.trim(),
          "Phone": _phone.text.trim(),
          "Password": _password.text,
        }),
      ).timeout(const Duration(seconds: 10));

      setState(() => loading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data["message"] ?? "Đăng ký thành công",
          Colors.green,
        );
        Navigator.pop(context); // Quay về login
      } else {
        final data = jsonDecode(response.body);
        _showSnackBar(
          data["detail"] ?? "Đăng ký thất bại",
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => loading = false);
      _showSnackBar(
        "Lỗi kết nối: $e",
        Colors.red,
      );
    }
  }

  @override
  void dispose() {
    _userName.dispose();
    _email.dispose();
    _phone.dispose();
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
          // Card với hiệu ứng mờ
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
                    constraints: BoxConstraints(
                      maxWidth: size.width > 450 ? 450 : size.width * 0.9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade300.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      "assets/logo3.jpg",
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.blue.shade600,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Tiêu đề
                                Text(
                                  "Đăng ký",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tạo tài khoản mới!",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Trường Tên Người Dùng
                                TextFormField(
                                  controller: _userName,
                                  validator: _validateUserName,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                  decoration: InputDecoration(
                                    labelText: "Tên người dùng",
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                    hintText: "Nhập tên người dùng",
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: Colors.blue.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade600,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Trường Email
                                TextFormField(
                                  controller: _email,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                    hintText: "Nhập email của bạn",
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: Colors.blue.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade600,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Trường Số Điện Thoại
                                TextFormField(
                                  controller: _phone,
                                  validator: _validatePhone,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                  decoration: InputDecoration(
                                    labelText: "Số điện thoại",
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                    hintText: "Nhập số điện thoại",
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: Colors.blue.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade600,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Trường Mật Khẩu
                                TextFormField(
                                  controller: _password,
                                  validator: _validatePassword,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => register(),
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                  decoration: InputDecoration(
                                    labelText: "Mật khẩu",
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                    hintText: "Nhập mật khẩu của bạn",
                                    prefixIcon: Icon(
                                      Icons.lock_outlined,
                                      color: Colors.blue.shade600,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade600,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Nút Đăng Ký
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: loading
                                      ? Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade600,
                                          Colors.blue.shade400,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.shade600.withOpacity(0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                    ),
                                  )
                                      : GestureDetector(
                                    onTapDown: (_) => setState(() => _buttonScale = 0.95),
                                    onTapUp: (_) => setState(() => _buttonScale = 1.0),
                                    onTapCancel: () => setState(() => _buttonScale = 1.0),
                                    child: AnimatedScale(
                                      scale: _buttonScale,
                                      duration: const Duration(milliseconds: 150),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade600,
                                              Colors.blue.shade400,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.shade600.withOpacity(0.5),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: register,
                                            borderRadius: BorderRadius.circular(16),
                                            child: Center(
                                              child: Text(
                                                "Đăng ký",
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Link Đăng Nhập
                                TextButton(
                                  onPressed: loading
                                      ? null
                                      : () => Navigator.pop(context),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Đã có tài khoản? ",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "Đăng nhập ngay",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Colors.blue.shade600,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      "© 2025 Trần Bảo Duy. All rights reserved.",
                                      style: TextStyle(
                                        color: Colors.blue.withOpacity(0.7),
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
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