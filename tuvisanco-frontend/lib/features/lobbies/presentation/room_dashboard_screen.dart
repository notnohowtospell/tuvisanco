import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/lobbies_provider.dart';

class RoomDashboardScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const RoomDashboardScreen({super.key, required this.roomCode});

  @override
  ConsumerState<RoomDashboardScreen> createState() => _RoomDashboardScreenState();
}

class _RoomDashboardScreenState extends ConsumerState<RoomDashboardScreen> {
  final _inviteUsernameController = TextEditingController();
  final _marketTitleController = TextEditingController();
  
  // Custom odds controller
  final List<TextEditingController> _oddControllers = [
    TextEditingController(text: '1.80'),
    TextEditingController(text: '2.50'),
  ];
  final List<String> _optionLabels = ['Đội Nhà', 'Đội Khách'];

  @override
  void initState() {
    super.initState();
    _refreshDetails();
  }

  void _refreshDetails() {
    Future.microtask(() {
      ref.read(lobbiesProvider.notifier).getLobbyDetails(widget.roomCode);
    });
  }

  @override
  void dispose() {
    _inviteUsernameController.dispose();
    _marketTitleController.dispose();
    for (var controller in _oddControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showAddMarketDialog(String roomId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusMd),
          topRight: Radius.circular(AppTheme.radiusMd),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thiết Lập Kèo Mới',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('TIÊU ĐỀ KÈO', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              TextField(
                controller: _marketTitleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Ví dụ: Ronaldo sẽ khóc trận này?",
                  hintStyle: TextStyle(color: AppTheme.textDisabled, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text('HỆ SỐ CƯỢC (ODDS)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _oddControllers[0],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Hệ số CÓ (YES)"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _oddControllers[1],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Hệ số KHÔNG (NO)"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final title = _marketTitleController.text.trim();
                  final odd1 = double.tryParse(_oddControllers[0].text) ?? 1.80;
                  final odd2 = double.tryParse(_oddControllers[1].text) ?? 2.50;

                  if (title.isEmpty) return;

                  Navigator.pop(context);

                  try {
                    await ref.read(lobbiesProvider.notifier).publishMarket(
                      roomId: roomId,
                      title: title,
                      category: 'FUN',
                      options: [
                        {'id': 'yes', 'label': 'Có', 'odd': odd1},
                        {'id': 'no', 'label': 'Không', 'odd': odd2},
                      ],
                      code: widget.roomCode,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xuất bản kèo cược thành công!'), backgroundColor: Colors.green),
                    );
                    _marketTitleController.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xuất bản kèo thất bại: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Xuất bản kèo'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteCoOwnerDialog(String roomId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Mời Co-owner Góp Vốn'),
          content: TextField(
            controller: _inviteUsernameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Nhập ID hoặc Username cần mời",
              hintStyle: TextStyle(color: AppTheme.textDisabled),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final inviteeId = _inviteUsernameController.text.trim();
                if (inviteeId.isEmpty) return;
                Navigator.pop(context);
                try {
                  await ref.read(lobbiesProvider.notifier).inviteCoOwner(roomId, inviteeId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi lời mời co-owner thành công!'), backgroundColor: Colors.green),
                  );
                  _inviteUsernameController.clear();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi gửi lời mời: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Gửi lời mời'),
            ),
          ],
        );
      },
    );
  }

  void _settleFunBet(String roomId, String marketId, String winningOptionId) async {
    try {
      await ref.read(lobbiesProvider.notifier).settleFunMarket(roomId, marketId, winningOptionId, widget.roomCode);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quyết toán kèo vui thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi quyết toán: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _dissolveLobby(String roomId) async {
    final user = ref.read(authProvider);
    try {
      await ref.read(lobbiesProvider.notifier).dissolveLobby(roomId, user.userId!, user.userId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phòng cược đã giải tán và phân chia quỹ!'), backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giải tán phòng thất bại: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lobbiesProvider);
    final room = state.currentRoomDetails;

    if (state.isLoading || room == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final isOwner = room['ownerId'] == ref.read(authProvider).userId;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(room['name']),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mã mời và thống kê
            Card(
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: const BorderSide(color: AppTheme.surfaceBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('MÃ MỜI THÀNH VIÊN', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room['code'],
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppTheme.primary, size: 20),
                          onPressed: () {
                            // Copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã sao chép mã mời vào bộ nhớ đệm.')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.surfaceBorder, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Tổng Quỹ', '${room['totalPool']} pts'),
                        _buildStatItem('Thành Viên', '${room['members']?.length ?? 0} người'),
                        _buildStatItem('Kèo Cược', '${room['markets']?.length ?? 0}/10'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Danh sách kèo đã tạo
            const Text(
              'DANH SÁCH KÈO CƯỢC',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (room['markets'] == null || room['markets'].isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text('Chưa xuất bản kèo cược nào.', style: TextStyle(color: AppTheme.textDisabled)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: room['markets'].length,
                itemBuilder: (context, index) {
                  final market = room['markets'][index];
                  final options = market['options'] as List<dynamic>;

                  return Card(
                    color: AppTheme.surfaceElevated,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  market['title'],
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: Text(
                                  market['status'],
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: options.map((opt) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    border: Border.all(color: AppTheme.surfaceBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(opt['label'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text('x${opt['odd']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          
                          // Quyết toán kèo vui (Nếu là kèo vui và chưa settle)
                          if (market['status'] == 'OPEN' || market['status'] == 'LOCKED') ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _settleFunBet(room['id'], market['id'], 'yes'),
                                  child: const Text('Quyết toán CÓ', style: TextStyle(color: Colors.greenAccent)),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _settleFunBet(room['id'], market['id'], 'no'),
                                  child: const Text('Quyết toán KHÔNG', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // Hành động
            if (isOwner) ...[
              ElevatedButton.icon(
                onPressed: () => _showAddMarketDialog(room['id']),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Thêm Kèo Cược'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showInviteCoOwnerDialog(room['id']),
                icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
                label: const Text('Mời Co-owner Góp Vốn'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _dissolveLobby(room['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Giải Tán Phòng (Dissolve)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
