import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/home_screen.dart';

// Mocks for Router setup
class MockMatchesScreen extends StatelessWidget {
  const MockMatchesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Thi Đấu')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Danh sách trận đấu & Dự đoán'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/lobby/ROOM123'),
              child: const Text('Vào phòng dự đoán nhóm (ROOM123)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/leaderboard'),
              child: const Text('Xem Bảng Xếp Hạng'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/news'),
              child: const Text('Tin Tức Bóng Đá'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/profile'),
              child: const Text('Xem Hồ Sơ Cá Nhân'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
            )
          ],
        ),
      ),
    );
  }
}

class MockLobbyScreen extends StatelessWidget {
  final String roomCode;
  const MockLobbyScreen({super.key, required this.roomCode});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phòng Dự Đoán: $roomCode')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bạn đang ở trong phòng $roomCode với bạn bè (Realtime WebSockets)'),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Thoát Phòng')),
          ],
        ),
      ),
    );
  }
}

class MockLeaderboardScreen extends StatelessWidget {
  const MockLeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng Xếp Hạng')),
      body: const Center(child: Text('Leaderboard Top 50')),
    );
  }
}

class MockNewsScreen extends StatelessWidget {
  const MockNewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin Tức Sân Cỏ')),
      body: const Center(child: Text('Tin tức bóng đá mới nhất')),
    );
  }
}

// Router Setup
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home', // Duc's screens redirect to /home upon login success
      builder: (context, state) => const MockMatchesScreen(),
    ),
    GoRoute(
      path: '/profile', // Map Duc's profile screen here
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/lobby/:code',
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? 'UNKNOWN';
        return MockLobbyScreen(roomCode: code);
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const MockLeaderboardScreen(),
    ),
    GoRoute(
      path: '/news',
      builder: (context, state) => const MockNewsScreen(),
    ),
  ],
);

