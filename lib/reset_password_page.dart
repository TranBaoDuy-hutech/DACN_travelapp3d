import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  int remainingSeconds = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    tokenController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Token đã hết hạn, vui lòng yêu cầu lại."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, "/forgot-password");
      }
    });
  }

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/customers/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": tokenController.text.trim(),
          "new_password": passwordController.text.trim(),
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Đặt lại mật khẩu thành công"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        final body = jsonDecode(response.body);
        final detail = body["detail"] ?? "Lỗi không xác định";

        if (!mounted) return;
        if (detail.contains("hết hạn")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Token đã hết hạn, vui lòng yêu cầu lại."),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacementNamed(context, "/forgot-password");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi: $detail"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi kết nối: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Đặt Lại Mật Khẩu",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Đặt Lại Mật Khẩu",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Nhập token từ email và mật khẩu mới của bạn.",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.timer, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              "Token hết hạn sau: $minutes:$seconds",
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Token Field
                        TextFormField(
                          controller: tokenController,
                          decoration: InputDecoration(
                            labelText: "Token từ email",
                            hintText: "Nhập token",
                            prefixIcon: Icon(Icons.vpn_key, color: Colors.blue.shade700),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Vui lòng nhập token";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Mật khẩu mới",
                            hintText: "Nhập mật khẩu mới",
                            prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Vui lòng nhập mật khẩu mới";
                            if (value.length < 6) return "Mật khẩu phải có ít nhất 6 ký tự";
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              shadowColor: Colors.blue.shade200,
                            ),
                            child: isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Xác Nhận",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, "/forgot-password"),
                            child: Text(
                              "Yêu cầu token mới",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Footer luôn dưới cùng
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "© 2025 Trần Bảo Duy. All rights reserved.",
                  style: TextStyle(
                    color: Colors.cyan.withOpacity(0.7),
                    fontSize: 15,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}