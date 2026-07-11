import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/daily_check_in_provider.dart';
import '../../../core/widgets/daily_check_in_dialog.dart';
import '../../lobbies/presentation/pl_dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi fetchStatus ngay khi màn hình khởi tạo để kiểm tra trạng thái điểm danh
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.userId != null) {
        ref.read(dailyCheckInProvider.notifier).fetchStatus(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Lắng nghe trạng thái điểm danh để tự động hiển thị popup 1 lần duy nhất trong session
    ref.listen<CheckInState>(dailyCheckInProvider, (previous, next) {
      if (next.canCheckInToday && !next.hasPromptedCheckIn && !next.isLoading) {
        // Đánh dấu đã hiển thị để tránh mở lặp lại
        ref.read(dailyCheckInProvider.notifier).setHasPrompted(true);
        DailyCheckInDialog.show(context, auth.userId!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ (Home)'),
        actions: [
          // Nút bấm mở nhanh Popup điểm danh (để người dùng chủ động xem lại tiến trình quà tặng)
          if (auth.userId != null)
            IconButton(
              icon: const Icon(Icons.card_giftcard_rounded, color: Colors.amber),
              onPressed: () {
                DailyCheckInDialog.show(context, auth.userId!);
              },
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text('Xin chào: ${auth.username ?? "Khách"}', style: const TextStyle(fontSize: 20)),
            Text('Email: ${auth.email ?? ""}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Số dư tài khoản: +${auth.points} Điểm 🌟',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 20),
            SelectableText('Mock JWT Token:\n${auth.token ?? ""}', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}