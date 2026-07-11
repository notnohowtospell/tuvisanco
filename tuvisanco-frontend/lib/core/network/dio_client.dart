import 'package:dio/dio.dart';

final dioClient = Dio(
  BaseOptions(
    baseUrl: 'http://10.0.2.2:3000', // Cổng mặc định của NestJS API Server
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ),
);
