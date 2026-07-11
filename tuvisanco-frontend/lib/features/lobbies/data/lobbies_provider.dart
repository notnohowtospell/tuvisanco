import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/auth_provider.dart';

// Model đại diện cho trạng thái của danh sách phòng cược
class LobbiesState {
  final List<dynamic> rooms;
  final List<dynamic> pendingInvitations;
  final dynamic currentRoomDetails;
  final bool isLoading;
  final String? error;

  LobbiesState({
    this.rooms = const [],
    this.pendingInvitations = const [],
    this.currentRoomDetails,
    this.isLoading = false,
    this.error,
  });

  LobbiesState copyWith({
    List<dynamic>? rooms,
    List<dynamic>? pendingInvitations,
    dynamic currentRoomDetails,
    bool? isLoading,
    String? error,
  }) {
    return LobbiesState(
      rooms: rooms ?? this.rooms,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      currentRoomDetails: currentRoomDetails ?? this.currentRoomDetails,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LobbiesNotifier extends Notifier<LobbiesState> {
  @override
  LobbiesState build() {
    return LobbiesState();
  }

  // 1. LẤY DANH SÁCH PHÒNG CỦA USER
  Future<void> fetchUserLobbies(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dioClient.get('/lobbies', queryParameters: {
        'userId': userId,
      });
      state = state.copyWith(
        rooms: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lấy danh sách phòng thất bại: $e',
      );
    }
  }

  // 1.5 LẤY DANH SÁCH LỜI MỜI CO-OWNER
  Future<void> fetchPendingInvitations(String userId) async {
    try {
      final response = await dioClient.get('/lobbies/pending-invitations/$userId');
      state = state.copyWith(pendingInvitations: response.data);
    } catch (e) {
      print('Lỗi lấy lời mời co-owner: $e');
    }
  }

  // 2. KHỞI TẠO PHÒNG CƯỢC MỚI
  Future<dynamic> createLobby({
    required String name,
    required String creatorId,
    required String matchId,
    required int maxMembers,
    required int contribution,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dioClient.post('/lobbies/create', data: {
        'name': name,
        'creatorId': creatorId,
        'matchId': matchId,
        'maxMembers': maxMembers,
        'contribution': contribution,
      });
      state = state.copyWith(isLoading: false);
      // Refresh danh sách
      await fetchUserLobbies(creatorId);
      return response.data;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Tạo phòng cược thất bại.',
      );
      rethrow;
    }
  }

  // 3. MỜI CO-OWNER
  Future<void> inviteCoOwner(String roomId, String inviteeId) async {
    try {
      await dioClient.post('/lobbies/invite-co-owner', data: {
        'roomId': roomId,
        'inviteeId': inviteeId,
      });
    } catch (e) {
      state = state.copyWith(error: 'Mời Co-owner thất bại: $e');
      rethrow;
    }
  }

  // 4. LẤY CHI TIẾT PHÒNG THEO CODE
  Future<void> getLobbyDetails(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dioClient.get('/lobbies/$code');
      state = state.copyWith(
        currentRoomDetails: response.data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lấy chi tiết phòng thất bại.',
      );
    }
  }

  // 5. GIA NHẬP PHÒNG BẰNG MÃ PIN (MEMBER)
  Future<dynamic> joinLobby(String userId, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await dioClient.post('/lobbies/join', data: {
        'userId': userId,
        'code': code,
      });
      state = state.copyWith(isLoading: false);
      await fetchUserLobbies(userId);
      return response.data;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gia nhập phòng thất bại.',
      );
      rethrow;
    }
  }

  // 6. ĐẶT CƯỢC KHÓA ĐIỂM (MEMBER)
  Future<void> placeBet({
    required String userId,
    required String roomId,
    required String marketId,
    required String optionId,
    required int points,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await dioClient.post('/lobbies/place-bet', data: {
        'userId': userId,
        'roomId': roomId,
        'marketId': marketId,
        'optionId': optionId,
        'points': points,
      });
      // Load lại chi tiết phòng cược sau khi đặt
      await getLobbyDetails(code);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Đặt cược thất bại.',
      );
      rethrow;
    }
  }

  // 7. XUẤT BẢN KÈO CƯỢC MỚI (ODDS CONFIGURATOR)
  Future<void> publishMarket({
    required String roomId,
    required String title,
    required String category,
    required List<dynamic> options,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await dioClient.post('/lobbies/publish-market', data: {
        'roomId': roomId,
        'title': title,
        'category': category,
        'options': options,
      });
      await getLobbyDetails(code);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Xuất bản kèo cược thất bại.',
      );
      rethrow;
    }
  }

  // 8. CHẤP NHẬN LỜI MỜI CO-OWNER
  Future<void> acceptCoOwner(String roomId, String userId, int contribution) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await dioClient.post('/lobbies/accept-co-owner', data: {
        'roomId': roomId,
        'userId': userId,
        'contribution': contribution,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Chấp nhận góp vốn thất bại.',
      );
      rethrow;
    }
  }

  // 9. QUYẾT TOÁN KÈO VUI
  Future<void> settleFunMarket(String roomId, String marketId, String winningOptionId, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await dioClient.post('/lobbies/settle-fun', data: {
        'roomId': roomId,
        'marketId': marketId,
        'winningOptionId': winningOptionId,
      });
      await getLobbyDetails(code);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Quyết toán kèo vui thất bại.',
      );
      rethrow;
    }
  }

  // 10. GIẢI TÁN PHÒNG
  Future<void> dissolveLobby(String roomId, String ownerId, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await dioClient.post('/lobbies/dissolve', data: {
        'roomId': roomId,
        'ownerId': ownerId,
      });
      state = state.copyWith(isLoading: false);
      await fetchUserLobbies(userId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Giải tán phòng cược thất bại.',
      );
      rethrow;
    }
  }
}

final lobbiesProvider = NotifierProvider<LobbiesNotifier, LobbiesState>(() {
  return LobbiesNotifier();
});
