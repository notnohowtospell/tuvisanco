import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String get baseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:3005';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Android emulator needs 10.0.2.2 to access localhost of the host machine
    return 'http://10.0.2.2:3005';
  }
  return 'http://127.0.0.1:3005';
}

final dioClient = Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
    },
  ),
);
