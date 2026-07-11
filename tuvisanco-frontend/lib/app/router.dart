import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/home_screen.dart';

// Import các màn hình Lobbies của Huy (Sẽ tạo ở bước tiếp theo)
import '../features/lobbies/presentation/rooms_screen.dart';
import '../features/lobbies/presentation/create_room_screen.dart';
import '../features/lobbies/presentation/room_dashboard_screen.dart';
import '../features/lobbies/presentation/join_room_screen.dart';
import '../features/lobbies/presentation/room_detail_screen.dart';
import '../features/lobbies/presentation/pl_dashboard_screen.dart';

// Mocks tạm cho các màn hình của thành viên khác để đảm bảo biên dịch thông suốt
class MockMatchesScreen extends StatelessWidget {
  const MockMatchesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Thi Đấu')),
      body: const Center(
        child: Text('Danh sách trận đấu bóng đá (Cường phụ trách)'),
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
      body: const Center(child: Text('Leaderboard Top 100 (Đức phụ trách)')),
    );
  }
}

class MockNewsScreen extends StatelessWidget {
  const MockNewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin Tức Sân Cỏ')),
      body: const Center(child: Text('Tin tức bóng đá mới nhất (Đức phụ trách)')),
    );
  }
}

// Lớp bọc chính để hiện Bottom Navigation Bar
class NavigationShellWrapper extends StatefulWidget {
  final Widget child;
  const NavigationShellWrapper({super.key, required this.child});

  @override
  State<NavigationShellWrapper> createState() => _NavigationShellWrapperState();
}

class _NavigationShellWrapperState extends State<NavigationShellWrapper> {
  int _currentIndex = 0;

  void _onTabTapped(BuildContext context, int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/rooms');
        break;
      case 2:
        context.go('/leaderboard');
        break;
      case 3:
        context.go('/news');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) {
      _currentIndex = 0;
    } else if (location.startsWith('/rooms')) {
      _currentIndex = 1;
    } else if (location.startsWith('/leaderboard')) {
      _currentIndex = 2;
    } else if (location.startsWith('/news')) {
      _currentIndex = 3;
    } else if (location.startsWith('/profile')) {
      _currentIndex = 4;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onTabTapped(context, index),
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textDisabled,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Phòng Cược',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_rounded),
            label: 'Xếp hạng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_rounded),
            label: 'Tin tức',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

// Cấu hình định tuyến chính của FootballAI
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
    ShellRoute(
      builder: (context, state, child) {
        return NavigationShellWrapper(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (context, state) => const MockMatchesScreen(),
        ),
        GoRoute(
          path: '/rooms',
          builder: (context, state) => const RoomsScreen(),
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (context, state) => const MockLeaderboardScreen(),
        ),
        GoRoute(
          path: '/news',
          builder: (context, state) => const MockNewsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    ),
    
    // Các màn hình dạng Push (không nằm dưới Bottom Nav)
    GoRoute(
      path: '/rooms/create',
      builder: (context, state) => const CreateRoomScreen(),
    ),
    GoRoute(
      path: '/rooms/join',
      builder: (context, state) => const JoinRoomScreen(),
    ),
    GoRoute(
      path: '/rooms/dashboard/:code',
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return RoomDashboardScreen(roomCode: code);
      },
    ),
    GoRoute(
      path: '/rooms/detail/:code',
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return RoomDetailScreen(roomCode: code);
      },
    ),
    GoRoute(
      path: '/rooms/pl/:code',
      builder: (context, state) {
        final code = state.pathParameters['code'] ?? '';
        return PLDashboardScreen(roomCode: code);
      },
    ),
  ],
);
