import 'package:dio/dio.dart';
import 'dart:io';

// Tự động chọn BaseUrl phù hợp: 10.0.2.2 cho Emulator, IP thật cho máy vật lý
String getSmartBaseUrl() {
  // Đạo hữu hãy thay IP này bằng IP máy tính của mình khi dùng máy thật
  const String pcIp = '10.0.2.2'; 
  
  try {
    if (Platform.isAndroid) {
      // Android Emulator dùng 10.0.2.2 để gọi về localhost của PC
      return 'http://$pcIp:3000';
    }
  } catch (e) {
    // Fallback cho Web hoặc các nền tảng khác
  }
  return 'http://localhost:3000';
}

final String apiBaseUrl = getSmartBaseUrl();

final dioClient = Dio(
  BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
    },
  ),
);
