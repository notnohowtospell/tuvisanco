import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sửa lại đường dẫn lùi 3 cấp thư mục để tìm đúng file auth_provider
import '../../../core/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trang Chủ (Home)')),
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