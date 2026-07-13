import 'package:dio/dio.dart';
import 'dart:io';

// IP máy ảo Android để kết nối tới Backend host (chạy ở cổng 3000)
const String _baseUrl = 'http://10.0.2.2:3000';

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
