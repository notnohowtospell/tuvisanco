import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // ĐÃ SỬA HOÀN CHỈNH: Lắng nghe trạng thái dựa vào isLoading để chuyển về /login
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }

      // Khi server xử lý xong (isLoading đổi từ true thành false) và không có lỗi xảy ra
      if (previous?.isLoading == true && next.isLoading == false && next.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký tài khoản thành công! Mời bạn đăng nhập."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Reset lại trạng thái bộ nhớ cho sạch
        ref.read(authProvider.notifier).logout();

        // Điều hướng trực tiếp về trang Đăng nhập
        Navigator.pushReplacementNamed(context, '/login');
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
                  // Logo vòng tròn Tử Vi Sân Cỏ
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF161F2C),
                          child: const Icon(Icons.brightness_7, color: Colors.blue, size: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "TỬ VI SÂN CỎ",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Hành Trình Vĩ Đại Bắt Đầu",
                    style: TextStyle(fontSize: 13, color: Color(0xFF7D8B9B)),
                  ),
                  const SizedBox(height: 24),

                  // Form Đăng ký tài khoản
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F2C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Đăng ký tài khoản",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text(
                            "Tham gia thế giới phong thủy bóng đá.",
                            style: TextStyle(color: Color(0xFF7D8B9B), fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 1. Ô nhập Họ và tên
                        const Text("Họ và tên", style: TextStyle(color: Color(0xFF9EACBC), fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(hintText: "Nguyễn Văn A", icon: Icons.person_outline),
                        ),
                        const SizedBox(height: 14),

                        // 2. Ô nhập Email
                        const Text("Email", style: TextStyle(color: Color(0xFF9EACBC), fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(hintText: "example@football.com", icon: Icons.email_outlined),
                        ),
                        const SizedBox(height: 14),

                        // 3. Ô nhập Mật khẩu
                        const Text("Mật khẩu", style: TextStyle(color: Color(0xFF9EACBC), fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(
                            hintText: "••••••••",
                            icon: Icons.lock_outline,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF4A5664),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4. Ô nhập Xác nhận mật khẩu
                        const Text("Xác nhận mật khẩu", style: TextStyle(color: Color(0xFF9EACBC), fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration(hintText: "••••••••", icon: Icons.lock_clock_outlined),
                        ),
                        const SizedBox(height: 14),

                        // Checkbox đồng ý điều khoản
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreeToTerms,
                                activeColor: const Color(0xFF3B66F5),
                                checkColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF2C3A4E)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "Tôi đồng ý với ",
                                  style: TextStyle(color: Color(0xFF9EACBC), fontSize: 11),
                                  children: [
                                    TextSpan(text: "Điều khoản", style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
                                    TextSpan(text: " & "),
                                    TextSpan(text: "Chính sách", style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
                                    TextSpan(text: " của Tử Vi Sân Cỏ."),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Nút Đăng ký ngay
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (authState.isLoading || !_agreeToTerms)
                                ? null
                                : () {
                              if (_passwordController.text != _confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Mật khẩu xác nhận không khớp!"), backgroundColor: Colors.red),
                                );
                                return;
                              }

                              FocusScope.of(context).unfocus();

                              ref.read(authProvider.notifier).registerWithEmail(
                                _nameController.text.trim(),
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B66F5),
                              disabledBackgroundColor: const Color(0xFF3B66F5).withOpacity(0.4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Đăng ký ngay", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // HOẶC TIẾP TỤC VỚI
                  Row(
                    children: [
                      Expanded(child: Divider(color: const Color(0xFF161F2C), thickness: 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text("HOẶC TIẾP TỤC VỚI", style: TextStyle(color: Color(0xFF4A5664), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: const Color(0xFF161F2C), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nút Google & Facebook mạng xã hội
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: authState.isLoading ? null : () => ref.read(authProvider.notifier).loginWithGoogle(),
                            icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 26),
                            label: const Text("Google", style: TextStyle(color: Colors.white, fontSize: 14)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF161F2C)),
                              backgroundColor: const Color(0xFF161F2C).withOpacity(0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.facebook, color: Colors.blue, size: 18),
                            label: const Text("Facebook", style: TextStyle(color: Colors.white, fontSize: 14)),
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
                  const SizedBox(height: 24),

                  // Chuyển sang màn Đăng nhập bằng tay
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Đã có tài khoản? ", style: TextStyle(color: Color(0xFF7D8B9B), fontSize: 13)),
                      GestureDetector(
                        onTap: () {
                          ref.read(authProvider.notifier).logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text("Đăng nhập", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Footer Bản quyền dưới đáy
                  const Text(
                    "© 2024 TỬ VI SÂN CỎ • PRECISION PREDICTIONS",
                    style: TextStyle(color: Color(0xFF4A5664), fontSize: 10, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF0F141C),
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF4A5664), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF4A5664), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}