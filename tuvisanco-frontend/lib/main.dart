import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Sửa lại đường dẫn bắt đầu bằng tương đối chính xác (thêm ./ hoặc dùng package)
import './features/auth/presentation/register_screen.dart';
import './features/auth/presentation/home_screen.dart'; 
import './features/auth/presentation/login_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TuViSanCoApp(),
    ),
  );
}

class TuViSanCoApp extends StatelessWidget {
  const TuViSanCoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tu Vi San Co',
      initialRoute: '/login', 
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}