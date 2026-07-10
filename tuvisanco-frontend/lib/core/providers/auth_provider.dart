import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

// 1. Model giữ nguyên cấu trúc của bạn
class AuthState {
  final String? token;
  final String? email;
  final String? username;
  final int points;
  final String? error;
  final bool isLoading;

  AuthState({
    this.token,
    this.email,
    this.username,
    this.points = 0,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    String? token,
    String? email,
    String? username,
    int? points,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      token: token ?? this.token,
      email: email ?? this.email,
      username: username ?? this.username,
      points: points ?? this.points,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 2. Notifier quản lý kết nối API thật
class AuthNotifier extends Notifier<AuthState> {
  // Định nghĩa Dio và Base URL kết nối Backend
  // ⚠️ LƯU Ý: Dùng 'http://10.0.2.2:3000' cho máy ảo Android. Nếu test máy thật dùng IP mạng LAN.
  // 🔴 Bật dòng này khi bạn quay lại test bằng MÁY ẢO Android Studio:
// final Dio _dio = Dio(BaseOptions(baseUrl: "http://10.0.2.2:3000/auth"));

// 🟢 Bật dòng này khi bạn test bằng ĐIỆN THOẠI THẬT qua mạng Wi-Fi:
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://192.168.1.101:3000/auth"));

  @override
  AuthState build() {
    return AuthState();
  }

  // ================= LUỒNG ĐĂNG KÝ THẬT =================
  void registerWithEmail(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    if (!email.contains('@')) {
      state = state.copyWith(isLoading: false, error: "Định dạng email không hợp lệ.");
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(isLoading: false, error: "Mật khẩu tối thiểu 6 ký tự.");
      return;
    }

    try {
      // Gọi API Đăng ký xuống NestJS
      final response = await _dio.post('/register', data: {
        "email": email,
        "password": password,
        "name": username, // Gửi lên trường 'name' để Backend hứng thành 'fullName'
      });

      // Lấy dữ liệu user mới tạo từ Backend trả về
      final userData = response.data['user'];

      state = AuthState(
        token: null, // Thường đăng ký xong bắt login lại, hoặc nếu NestJS tự login thì truyền token vào đây
        email: userData['email'],
        username: userData['fullName'],
        points: userData['totalPoints'] ?? 200, // Điểm khởi tạo từ Postgres
        isLoading: false,
      );
    } on DioException catch (e) {
      // Bốc lỗi từ NestJS gửi về (ví dụ: 'Email này đã được sử dụng!')
      final errorMessage = e.response?.data['message'] ?? "Đăng ký thất bại.";
      state = state.copyWith(isLoading: false, error: errorMessage.toString());
    }
  }

  // ================= LUỒNG ĐĂNG NHẬP THẬT =================
  void loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Gọi API Đăng nhập xuống NestJS
      final response = await _dio.post('/login', data: {
        "email": email,
        "password": password,
      });

      final String token = response.data['access_token'];
      final userData = response.data['user'];

      // Lưu trạng thái đăng nhập thành công với dữ liệu THẬT từ Database
      state = AuthState(
        token: token,
        email: userData['email'],
        username: userData['name'], // Backend trả về trường 'name' chứa 'fullName'
        points: userData['totalPoints'] ?? 200,
        isLoading: false,
      );
    } on DioException catch (e) {
      // Bốc lỗi UnauthorizedException từ NestJS (ví dụ: 'Email hoặc mật khẩu không chính xác!')
      final errorMessage = e.response?.data['message'] ?? "Đăng nhập thất bại.";
      state = state.copyWith(isLoading: false, error: errorMessage.toString());
    }
  }

  // 1b. Luồng Google OAuth (Tạm thời giữ nguyên Mock, khi nào làm OAuth thì cập nhật sau)
  void loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = AuthState(
      token: "mock_google_login_jwt_token_888",
      email: "google.login@gmail.com",
      username: "Google Member",
      points: 750,
      isLoading: false,
    );
  }

  void logout() {
    state = AuthState();
  }
}

// 3. Provider toàn cục giữ nguyên
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});