import 'package:dio/dio.dart';
import 'dart:io';

// IP máy tính của bạn (Dùng được cho cả Máy thật và Máy ảo nếu cùng mạng Wi-Fi)
const String _baseUrl = 'http://192.168.100.32:3000';

// Nếu ai trong nhóm muốn dùng IP máy ảo riêng của họ (10.0.2.2), có thể đổi biến này
// const String _baseUrl = 'http://10.0.2.2:3000';

final dioClient = Dio(
  BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ),
);
