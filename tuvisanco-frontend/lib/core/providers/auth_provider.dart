import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

// 1. Model giữ nguyên cấu trúc của bạn
class AuthState {
  final String? userId;
  final String? token;
  final String? email;
  final String? username;
  final int points;
  final String? error;
  final bool isLoading;

  AuthState({
    this.userId,
    this.token,
    this.email,
    this.username,
    this.points = 0,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    String? userId,
    String? token,
    String? email,
    String? username,
    int? points,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
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
      // ĐÃ SỬA: Sử dụng dioClient dùng chung cho toàn dự án
      final response = await dioClient.post('/auth/register', data: {
        "email": email,
        "password": password,
        "name": username, // Gửi lên trường 'name' để Backend hứng thành 'fullName'
      });

      // Lấy dữ liệu user mới tạo từ Backend trả về
      final userData = response.data['user'];

      state = AuthState(
        userId: userData['id'],
        token: null, // Thường đăng ký xong bắt login lại, hoặc nếu NestJS tự login thì truyền token vào đây
        email: userData['email'],
        username: userData['fullName'],
        points: userData['totalPoints'] ?? 200, // Điểm khởi tạo từ Postgres
        isLoading: false,
      );
    } on DioException catch (e) {
      // Bốc lỗi chi tiết để dễ dàng kiểm tra
      String errorMessage = "Lỗi kết nối server.";
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = "Kết nối quá hạn (Timeout). Kiểm tra IP/Firewall.";
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = "Không thể kết nối tới server. Kiểm tra Wi-Fi và IP.";
      } else if (e.response != null) {
        // Lỗi từ phía Server trả về (400, 401, 404, 500)
        errorMessage = e.response?.data['message']?.toString() ?? "Lỗi server (${e.response?.statusCode})";
      } else {
        errorMessage = e.message ?? "Đăng ký thất bại.";
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  // ================= LUỒNG ĐĂNG NHẬP THẬT =================
  void loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Gọi API Đăng nhập xuống NestJS
      // ĐÃ SỬA: Sử dụng dioClient dùng chung
      final response = await dioClient.post('/auth/login', data: {
        "email": email,
        "password": password,
      });

      final String token = response.data['access_token'];
      final userData = response.data['user'];

      // Lưu trạng thái đăng nhập thành công với dữ liệu THẬT từ Database
      state = AuthState(
        userId: userData['id'],
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
      userId: "mock-google-user-uuid-1234",
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

  void updatePoints(int newPoints) {
    state = state.copyWith(points: newPoints);
  }
}

// 3. Provider toàn cục giữ nguyên
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});