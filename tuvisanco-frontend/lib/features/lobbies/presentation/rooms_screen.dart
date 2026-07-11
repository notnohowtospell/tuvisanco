import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/lobbies_provider.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    _refreshRooms();
  }

  void _refreshRooms() {
    Future.microtask(() {
      final user = ref.read(authProvider);
      if (user.userId != null) {
        ref.read(lobbiesProvider.notifier).fetchUserLobbies(user.userId!);
        ref.read(lobbiesProvider.notifier).fetchPendingInvitations(user.userId!);
      }
    });
  }

  // Alias helper to fetch pending co-owner invites
  Future<void> _fetchPendingInvites(String userId) async {
    ref.read(lobbiesProvider.notifier).fetchPendingInvitations(userId);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final lobbiesState = ref.watch(lobbiesProvider);
    final pendingInvites = lobbiesState.pendingInvitations;

    // Trigger loading invitations in microtask if logged in and list empty on load
    if (user.userId != null && pendingInvites.isEmpty && !lobbiesState.isLoading) {
      Future.microtask(() => _fetchPendingInvites(user.userId!));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Phòng Cược Nhóm'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshRooms,
          ),
        ],
      ),
      body: user.userId == null
          ? const Center(
              child: Text(
                'Vui lòng đăng nhập để xem phòng cược.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : lobbiesState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hiển thị lời mời Co-owner chờ chấp nhận nếu có
                      if (pendingInvites.isNotEmpty)
                        _buildPendingInvitesSection(context, pendingInvites),
                      
                      // 2. Tiêu đề mục chính
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'DANH SÁCH PHÒNG CỦA BẠN',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // 3. Danh sách phòng cược hoặc Empty State
                      lobbiesState.rooms.isEmpty
                          ? SizedBox(
                              height: 300,
                              child: _buildEmptyState(context),
                            )
                          : _buildRoomsList(context, lobbiesState.rooms),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget _buildPendingInvitesSection(BuildContext context, List<dynamic> invites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'LỜI MỜI ĐỒNG CHỦ PHÒNG CHỜ BẠN GÓP VỐN',
            style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              final String ownerName = invite['room']?['owner']?['fullName'] ?? 'Chủ phòng';
              final String roomName = invite['room']?['name'] ?? 'Phòng cược';

              return Card(
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  side: const BorderSide(color: AppTheme.warning, width: 1.2),
                ),
                margin: const EdgeInsets.only(right: 12, bottom: 8),
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Từ: $ownerName',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: () => _showAcceptInviteDialog(context, invite),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warning,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Góp vốn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAcceptInviteDialog(BuildContext context, dynamic invite) {
    final controller = TextEditingController(text: '200');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          title: const Text('Góp Vốn Làm Co-owner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn được mời góp vốn vào phòng: ${invite['room']?['name']}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('SỐ ĐIỂM GÓP VỐN (POOL CONTRIBUTION)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  suffixText: 'Điểm',
                  suffixStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Yêu cầu góp tối thiểu 200 điểm.', style: TextStyle(color: AppTheme.textDisabled, fontSize: 11)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Từ chối', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final int? contribution = int.tryParse(controller.text);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                if (contribution == null || contribution < 200) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Số vốn tối thiểu là 200 điểm.'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                final user = ref.read(authProvider);
                if (contribution > user.points) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Số dư điểm không đủ.'), backgroundColor: Colors.red),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  await ref.read(lobbiesProvider.notifier).acceptCoOwner(
                    invite['roomId'],
                    user.userId!,
                    contribution,
                  );
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Chấp nhận lời mời làm chủ phòng thành công!'), backgroundColor: Colors.green),
                  );
                  _refreshRooms();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Góp vốn thất bại: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Xác nhận góp'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 80, color: AppTheme.textDisabled.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'Chưa Có Phòng Cược Nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy tự tạo một phòng cược làm nhà cái hoặc tham gia phòng cược của bạn bè bằng mã PIN.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList(BuildContext context, List<dynamic> rooms) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        final bool isOwner = room['ownerId'] == ref.read(authProvider).userId;
        final String matchDesc = room['match'] != null
            ? "${room['match']['homeTeam']} vs ${room['match']['awayTeam']}"
            : "Chưa chọn trận";

        final int memberCount = room['members']?.length ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            side: const BorderSide(color: AppTheme.surfaceBorder),
          ),
          child: InkWell(
            onTap: () {
              if (isOwner) {
                context.push('/rooms/dashboard/${room['code']}');
              } else {
                context.push('/rooms/detail/${room['code']}');
              }
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        room['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      _buildStatusBadge(room['status']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    matchDesc,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined, color: AppTheme.warning, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Quỹ: ${room['totalPool']} pts',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$memberCount/${room['maxMembers']} thành viên',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOwner ? AppTheme.accentPurple.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          isOwner ? 'NHÀ CÁI' : 'CON BẠC',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isOwner ? AppTheme.accentPurple : Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String label;
    switch (status) {
      case 'SETUP':
        badgeColor = AppTheme.neutral;
        label = 'SETUP';
        break;
      case 'OPEN':
        badgeColor = AppTheme.success;
        label = 'OPEN';
        break;
      case 'LOCKED':
        badgeColor = AppTheme.warning;
        label = 'LOCKED';
        break;
      case 'SETTLED':
        badgeColor = Colors.blue;
        label = 'FINISHED';
        break;
      case 'ARCHIVED':
        badgeColor = AppTheme.error;
        label = 'ARCHIVED';
        break;
      default:
        badgeColor = AppTheme.neutral;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push('/rooms/join'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.surfaceBorder),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Gia Nhập Phòng'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.push('/rooms/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Tạo Phòng Mới'),
            ),
          ),
        ],
      ),
    );
  }
}
