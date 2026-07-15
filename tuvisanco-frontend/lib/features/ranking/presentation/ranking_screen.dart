import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  String _selectedPeriod = 'Tuần này';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // 1. Filter Tabs
                  _buildPeriodTabs(),
                  
                  const SizedBox(height: 30),
                  
                  // 2. Podium (Rank 1, 2, 3)
                  _buildPodium(),
                  
                  const SizedBox(height: 30),
                  
                  // 3. Table Header
                  _buildTableHeader(),
                  
                  // 4. Rankings List
                  _buildRankingList(),
                ],
              ),
            ),
          ),
          
          // 5. My Rank Fixed Bottom
          _buildMyRankBottom(authState.username ?? 'Bạn'),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    final periods = ['Tuần này', 'Tháng này', 'Tất cả'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161F2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((p) {
          bool isSelected = _selectedPeriod == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B66F5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    p,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodium() {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Rank 2
          Positioned(
            left: 20,
            bottom: 20,
            child: _buildPodiumItem(
              name: 'Tiên Phong',
              winRate: '82% Thắng',
              rank: 2,
              avatar: Icons.person,
              color: Colors.grey[400]!,
            ),
          ),
          // Rank 3
          Positioned(
            right: 20,
            bottom: 20,
            child: _buildPodiumItem(
              name: 'Ngọc Nữ',
              winRate: '78% Thắng',
              rank: 3,
              avatar: Icons.person_3,
              color: Colors.orange[300]!,
            ),
          ),
          // Rank 1
          Positioned(
            bottom: 40,
            child: _buildPodiumItem(
              name: 'Lão Đạo Hữu',
              winRate: '84% Thắng',
              points: '+43.8 pts',
              rank: 1,
              avatar: Icons.face_retouching_natural,
              color: Colors.amber,
              isLarge: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required String name,
    required String winRate,
    String? points,
    required int rank,
    required IconData avatar,
    required Color color,
    bool isLarge = false,
  }) {
    double size = isLarge ? 90 : 70;
    return Column(
      children: [
        if (rank == 1) const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size + 8,
              height: size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                gradient: RadialGradient(colors: [color.withOpacity(0.3), Colors.transparent]),
              ),
            ),
            CircleAvatar(
              radius: size / 2,
              backgroundColor: const Color(0xFF1E2736),
              child: Icon(avatar, color: Colors.white70, size: size * 0.6),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text('$rank', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(winRate, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
        if (points != null)
          Text(points, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 30, child: Text('XH', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(child: Text('TIÊN TRI', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold))),
          Text('HIỆU SỐ', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
          SizedBox(width: 60, child: Text('TỶ LỆ', textAlign: TextAlign.right, style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRankingList() {
    final users = [
      {'rank': 4, 'name': 'Khổng Minh Soi', 'points': '+19.4', 'winRate': '75%', 'streak': '3 🔥'},
      {'rank': 5, 'name': 'Thành Chốt', 'points': '+15.2', 'winRate': '72%', 'streak': '7 🔥'},
      {'rank': 6, 'name': 'Ẩn Danh 07', 'points': '+9.8', 'winRate': '69%', 'streak': ''},
      {'rank': 7, 'name': 'Tử Vi Số', 'points': '+5.2', 'winRate': '65%', 'streak': '2 🔥'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF161F2C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('${user['rank']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const CircleAvatar(radius: 18, backgroundColor: Color(0xFF1E2736), child: Icon(Icons.person, size: 18, color: Colors.white24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF1E2736), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Theo dõi', style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Text(user['points'] as String, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(user['winRate'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    if ((user['streak'] as String).isNotEmpty)
                      Text(user['streak'] as String, style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyRankBottom(String name) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF3B66F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Column(
              children: const [
                Text('HẠNG', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                Text('124', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 20),
            const CircleAvatar(radius: 20, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white70)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bạn ($name)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Tiến độ: ●●●●●○○', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text('TỶ LỆ', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                Text('45%', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
