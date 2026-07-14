import 'package:dio/dio.dart';

// ĐÃ SỬA: Dùng chính xác IP máy tính của đạo hữu để máy thật và máy ảo đều dùng được
const String _baseUrl = 'http://192.168.100.32:3000';

final dioClient = Dio(
  BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
    },
  ),
);
