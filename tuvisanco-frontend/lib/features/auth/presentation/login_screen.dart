import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ĐÃ SỬA: Import đúng đường dẫn gốc đi từ thư mục lib
import '../../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Lắng nghe trạng thái từ Backend gửi về
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
      if (next.token != null && next.isLoading == false && next.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng nhập thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Logo.png',
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF161F2C),
                          child: const Icon(Icons.brightness_7, color: Colors.blue, size: 45),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "TỬ VI SÂN CỎ",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Ngọa Long - Phượng Sồ Tranh Hùng",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7D8B9B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F2C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Email",
                          style: TextStyle(color: Color(0xFF9EACBC), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F141C),
                            hintText: "example@football.vn",
                            hintStyle: const TextStyle(color: Color(0xFF4A5664)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Mật khẩu",
                              style: TextStyle(color: Color(0xFF9EACBC), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                "Quên mật khẩu?",
                                style: TextStyle(color: Color(0xFF2F6CE5), fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F141C),
                            hintText: "••••••••",
                            hintStyle: const TextStyle(color: Color(0xFF4A5664)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // NÚT ĐĂNG NHẬP
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: authState.isLoading
                                ? null
                                : () {
                              // ĐÃ SỬA: Tự động ẩn bàn phím điện thoại khi bấm nút
                              FocusScope.of(context).unfocus();

                              ref.read(authProvider.notifier).loginWithEmail(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                                : const Text("Đăng nhập", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // NÚT CHUYỂN SANG ĐĂNG KÝ
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              // ĐÃ SỬA: Xóa sạch thông báo lỗi cũ lưu trong Provider trước khi nhảy trang
                              ref.read(authProvider.notifier).logout();
                              Navigator.pushReplacementNamed(context, '/register');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2C3A4E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Đăng ký tài khoản",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(child: Divider(color: const Color(0xFF161F2C), thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "HOẶC TIẾP TỤC VỚI",
                          style: TextStyle(color: Color(0xFF4A5664), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(child: Divider(color: const Color(0xFF161F2C), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : () => ref.read(authProvider.notifier).loginWithGoogle(),
                            icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                            label: const Text("Google", style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF161F2C)),
                              backgroundColor: const Color(0xFF161F2C).withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.facebook, color: Colors.blue, size: 20),
                            label: const Text("Facebook", style: TextStyle(color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF161F2C)),
                              backgroundColor: const Color(0xFF161F2C).withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  const Text.rich(
                    TextSpan(
                      text: "Khi đăng nhập, bạn đồng ý với ",
                      style: TextStyle(color: Color(0xFF4A5664), fontSize: 12),
                      children: [
                        TextSpan(
                          text: "Điều khoản dịch vụ",
                          style: TextStyle(color: Color(0xFF7D8B9B), decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: " và "),
                        TextSpan(
                          text: "Chính sách bảo mật",
                          style: TextStyle(color: Color(0xFF7D8B9B), decoration: TextDecoration.underline),
                        ),
                        TextSpan(text: " của chúng tôi."),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}