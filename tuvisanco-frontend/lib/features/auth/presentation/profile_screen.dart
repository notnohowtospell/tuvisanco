import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/daily_check_in_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final auth = ref.read(authProvider);
    if (auth.userId == null) return;
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.get('http://10.0.2.2:3000/users/${auth.userId}');
      if (mounted) {
        setState(() {
          _profileData = response.data;
          _isLoading = false;
        });
        // Đồng bộ điểm lên AuthProvider để các tab khác hiển thị đúng điểm số mới nhất
        if (_profileData != null && _profileData!['totalPoints'] != null) {
          ref.read(authProvider.notifier).updatePoints(_profileData!['totalPoints']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleLogout() {
    // Mở hộp thoại xác nhận đăng xuất
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Đăng Xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Thực hiện đăng xuất
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final String initial = (auth.username ?? 'U').isNotEmpty ? auth.username![0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Hồ Sơ Cá Nhân'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // 1. Khung thông tin Avatar & Name dạng Card bóng bẩy
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        // Avatar với viền Gradient sáng rực
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, Colors.purpleAccent],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: AppTheme.surfaceElevated,
                            child: Text(
                              initial,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          auth.username ?? 'Người dùng',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.email ?? '',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        // Badge hiển thị Vai trò
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _profileData?['role'] == 'ADMIN' ? 'QUẢN TRỊ VIÊN' : 'THÀNH VIÊN',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Grid hiển thị các chỉ số điểm, chuỗi dự đoán (Stats Grid)
                  Row(
                    children: [
                      // Card Điểm số
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.stars, color: Colors.amber, size: 20),
                                  SizedBox(width: 6),
                                  Text('Điểm số', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${auth.points} pts',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Card Chuỗi thắng (Streak)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bolt, color: Colors.amber, size: 20),
                                  SizedBox(width: 6),
                                  Text('Chuỗi thắng', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_profileData?['streakCurrent'] ?? 0} / ${_profileData?['streakMax'] ?? 0}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Menu danh sách cấu hình/hoạt động
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      children: [
                        // Nút Điểm danh nhận quà
                        _buildMenuItem(
                          icon: Icons.card_giftcard_rounded,
                          iconColor: Colors.amber,
                          title: 'Điểm danh 7 ngày',
                          subtitle: 'Nhận điểm cược mỗi ngày',
                          onTap: () {
                            DailyCheckInDialog.show(context, auth.userId!);
                          },
                        ),
                        const Divider(color: AppTheme.surfaceBorder, height: 1),
                        // Hướng dẫn / Điều khoản luật chơi
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          iconColor: Colors.blue,
                          title: 'Hướng dẫn chơi cược',
                          subtitle: 'Xem quy chế & luật phân chia điểm',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Hướng dẫn luật chơi đang được biên soạn.')),
                            );
                          },
                        ),
                        const Divider(color: AppTheme.surfaceBorder, height: 1),
                        // Đổi ngôn ngữ (Mock)
                        _buildMenuItem(
                          icon: Icons.language,
                          iconColor: Colors.teal,
                          title: 'Ngôn ngữ',
                          subtitle: 'Tiếng Việt',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Hiện tại ứng dụng chỉ hỗ trợ Tiếng Việt.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4. Nút Đăng Xuất (Log Out) nổi bật dưới cùng
                  ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                    label: const Text(
                      'ĐĂNG XUẤT',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textDisabled),
      onTap: onTap,
    );
  }
}
