import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'auth_provider.dart';
import '../network/dio_client.dart';

class CheckInDay {
  final int dayIndex;
  final int points;
  final String status; // 'claimed', 'today', 'locked'

  CheckInDay({
    required this.dayIndex,
    required this.points,
    required this.status,
  });

  factory CheckInDay.fromJson(Map<String, dynamic> json) {
    return CheckInDay(
      dayIndex: json['dayIndex'],
      points: json['points'],
      status: json['status'],
    );
  }
}

class CheckInState {
  final bool canCheckInToday;
  final int currentStreak;
  final List<CheckInDay> history;
  final bool isLoading;
  final String? error;
  final bool hasPromptedCheckIn; // Cờ kiểm soát hiển thị popup 1 lần duy nhất

  CheckInState({
    this.canCheckInToday = false,
    this.currentStreak = 0,
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.hasPromptedCheckIn = false,
  });

  CheckInState copyWith({
    bool? canCheckInToday,
    int? currentStreak,
    List<CheckInDay>? history,
    bool? isLoading,
    String? error,
    bool? hasPromptedCheckIn,
  }) {
    return CheckInState(
      canCheckInToday: canCheckInToday ?? this.canCheckInToday,
      currentStreak: currentStreak ?? this.currentStreak,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasPromptedCheckIn: hasPromptedCheckIn ?? this.hasPromptedCheckIn,
    );
  }
}

class DailyCheckInNotifier extends Notifier<CheckInState> {


  @override
  CheckInState build() {
    return CheckInState();
  }

  void setHasPrompted(bool value) {
    state = state.copyWith(hasPromptedCheckIn: value);
  }

  Future<void> fetchStatus(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dioClient.get('/users/check-in-status/$userId');
      final data = response.data;
      final List<dynamic> historyJson = data['history'] ?? [];
      final historyList = historyJson.map((e) => CheckInDay.fromJson(e)).toList();

      state = CheckInState(
        canCheckInToday: data['canCheckInToday'] ?? false,
        currentStreak: data['currentStreak'] ?? 0,
        history: historyList,
        isLoading: false,
        hasPromptedCheckIn: state.hasPromptedCheckIn, // giữ nguyên cờ
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<int?> performCheckIn(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dioClient.post('/users/check-in', data: {
        "userId": userId,
      });
      final data = response.data;
      if (data['success'] == true) {
        final int pointsEarned = data['pointsEarned'];
        final int totalPoints = data['totalPoints'];

        // Cập nhật lại số điểm của người dùng trong AuthProvider
        ref.read(authProvider.notifier).updatePoints(totalPoints);

        // Đánh dấu đã hiện popup để không hiện lại
        setHasPrompted(true);

        // Fetch lại trạng thái điểm danh sau khi điểm danh thành công
        await fetchStatus(userId);

        return pointsEarned;
      }
      state = state.copyWith(isLoading: false);
      return null;
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['message'] ?? "Điểm danh thất bại.";
      state = state.copyWith(
        isLoading: false,
        error: serverMsg.toString(),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

final dailyCheckInProvider = NotifierProvider<DailyCheckInNotifier, CheckInState>(() {
  return DailyCheckInNotifier();
});
