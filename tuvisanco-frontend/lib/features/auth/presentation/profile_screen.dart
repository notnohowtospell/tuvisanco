import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/daily_check_in_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final auth = ref.read(authProvider);
    if (auth.userId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await dioClient.get('/users/${auth.userId}');
      if (mounted) {
        setState(() {
          _userData = response.data;
          _isLoading = false;
        });
        if (_userData != null && _userData!['totalPoints'] != null) {
          ref.read(authProvider.notifier).updatePoints(_userData!['totalPoints']);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B66F5)))
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 1. Header: Avatar & Name
                  _buildHeader(auth.username ?? 'Đạo hữu'),
                  
                  const SizedBox(height: 30),
                  
                  // 2. Points & Wallet Cards
                  Row(
                    children: [
                      _buildInfoCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'VÍ CỦA TÔI',
                        value: '1.250.000',
                        unit: 'VND',
                      ),
                      const SizedBox(width: 12),
                      _buildInfoCard(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                        title: 'ĐIỂM TÍCH LŨY',
                        value: auth.points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                        unit: 'Stars',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 3. Menu Actions
                  _buildMenuSection(),
                  
                  const SizedBox(height: 20),
                  
                  // 4. Logout Button
                  _buildLogoutBtn(),
                  
                  const SizedBox(height: 24),
                  
                  // 5. Achievement Card
                  _buildAchievementCard(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3B66F5).withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B66F5).withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/ChatBox.png'),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFF3B66F5), shape: BoxShape.circle),
              child: const Icon(Icons.verified, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.brightness_7, color: Colors.blueAccent, size: 14),
            SizedBox(width: 6),
            Text('Nhà Tiên Tri Kim Cương', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value, required String unit, Color iconColor = Colors.white54}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161F2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.share_outlined, 'Chia sẻ ứng dụng'),
          _buildDivider(),
          _buildMenuItem(Icons.history_outlined, 'Lịch sử dự đoán'),
          _buildDivider(),
          _buildMenuItem(Icons.settings_outlined, 'Cài đặt tài khoản'),
          _buildDivider(),
          _buildMenuItem(Icons.headset_mic_outlined, 'Hỗ trợ & Góp ý'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white10, size: 20),
      onTap: () {},
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 50);

  Widget _buildLogoutBtn() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          ref.read(authProvider.notifier).logout();
          context.go('/login');
        },
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C0F12),
          foregroundColor: const Color(0xFFE57373),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildAchievementCard() {
    final streak = _userData?['streakMax'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thành tựu Tiên tri', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Icon(Icons.auto_awesome, color: Colors.white10, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('TỈ LỆ THẮNG', '68%'),
              _buildStat('CHUỖI THẮNG', '$streak'),
              _buildStat('XẾP HẠNG', '#42'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
