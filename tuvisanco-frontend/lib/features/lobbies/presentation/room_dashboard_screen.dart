import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/lobbies_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

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
  
  bool _showStats = false;

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

  Widget _teamLogo(String? url, Color fallbackColor, {double size = 24}) {
    if (url == null || url.isEmpty) {
      return Icon(Icons.shield, color: fallbackColor, size: size);
    }
    final originalUrl = url.trim();
    final proxiedUrl = 'http://192.168.100.32:3000/matches/proxy/image?url=' + Uri.encodeComponent(originalUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 8),
      child: originalUrl.toLowerCase().endsWith('.svg')
          ? SvgPicture.network(
              proxiedUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => Icon(Icons.shield, color: fallbackColor, size: size),
            )
          : Image.network(
              proxiedUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.shield, color: fallbackColor, size: size),
            ),
    );
  }

  Widget _buildMiniStatBar(String title, int homeVal, int awayVal, {Color homeColor = Colors.greenAccent, Color awayColor = Colors.amber}) {
    int total = homeVal + awayVal;
    if (total == 0) total = 1;
    double homeRatio = homeVal / total;
    double awayRatio = awayVal / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$homeVal', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text('$awayVal', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), bottomLeft: Radius.circular(3)),
                  child: LinearProgressIndicator(
                    value: homeRatio,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(homeColor),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
                  child: LinearProgressIndicator(
                    value: awayRatio,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(awayColor),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

                  final scaffoldMessenger = ScaffoldMessenger.of(context);
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
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Xuất bản kèo cược thành công!'), backgroundColor: Colors.green),
                    );
                    _marketTitleController.clear();
                  } catch (e) {
                    String message = e.toString();
                    if (e is DioException) {
                      final serverMsg = e.response?.data?['message'];
                      if (serverMsg != null) {
                        message = serverMsg is List ? serverMsg.join(', ') : serverMsg.toString();
                      }
                    }
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Xuất bản kèo thất bại: $message'), backgroundColor: Colors.red),
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
              hintText: "Nhập Email hoặc ID cần mời",
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
                
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await ref.read(lobbiesProvider.notifier).inviteCoOwner(roomId, inviteeId);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Đã gửi lời mời co-owner thành công!'), backgroundColor: Colors.green),
                  );
                  _inviteUsernameController.clear();
                } catch (e) {
                  String message = e.toString();
                  if (e is DioException) {
                    final serverMsg = e.response?.data?['message'];
                    if (serverMsg != null) {
                      message = serverMsg is List ? serverMsg.join(', ') : serverMsg.toString();
                    }
                  }
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Lỗi gửi lời mời: $message'), backgroundColor: Colors.red),
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
      String message = e.toString();
      if (e is DioException) {
        final serverMsg = e.response?.data?['message'];
        if (serverMsg != null) {
          message = serverMsg is List ? serverMsg.join(', ') : serverMsg.toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi quyết toán: $message'), backgroundColor: Colors.red),
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
      String message = e.toString();
      if (e is DioException) {
        final serverMsg = e.response?.data?['message'];
        if (serverMsg != null) {
          message = serverMsg is List ? serverMsg.join(', ') : serverMsg.toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giải tán phòng thất bại: $message'), backgroundColor: Colors.red),
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
    final match = room['match'];
    final DateTime? matchTime = match != null && match['startTime'] != null 
        ? DateTime.tryParse(match['startTime'].toString()) 
        : null;

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
      body: RefreshIndicator(
        onRefresh: () async => _refreshDetails(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Card Trận Đấu Cao Cấp (Premium Match Card)
              if (match != null) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B2342), Color(0xFF0F141C)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // League Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                match['leagueName'] ?? 'Giải đấu',
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Host: ${room['owner']['fullName']}',
                                style: const TextStyle(color: AppTheme.warning, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      // Match Teams & Score Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            // Home Team
                            Expanded(
                              child: Column(
                                children: [
                                  _teamLogo(match['homeLogo'], Colors.blueAccent, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    match['homeTeam'] ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            // Score & Status Center
                            SizedBox(
                              width: 100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (match['status'] == 'NS') ...[
                                    Text(
                                      matchTime != null ? DateFormat('HH:mm').format(matchTime.toLocal()) : '--:--',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Sắp diễn ra',
                                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                                    ),
                                  ] else ...[
                                    Text(
                                      '${match['homeScore']} - ${match['awayScore']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                    ),
                                    const SizedBox(height: 4),
                                    if (match['status'] == 'LIVE')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "LIVE ${match['minuteElapsed']}'",
                                          style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Đã kết thúc',
                                        style: TextStyle(color: Colors.white54, fontSize: 10),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                            // Away Team
                            Expanded(
                              child: Column(
                                children: [
                                  _teamLogo(match['awayLogo'], Colors.redAccent, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    match['awayTeam'] ?? '',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Live Stats Accordion
                if (match['status'] != 'NS') ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _showStats = !_showStats),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Thông số trận đấu trực tiếp',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Spacer(),
                          Icon(
                            _showStats ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showStats) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Column(
                        children: [
                          _buildMiniStatBar('Sút bóng', (match['homeShots'] as num?)?.toInt() ?? 0, (match['awayShots'] as num?)?.toInt() ?? 0),
                          _buildMiniStatBar('Thẻ vàng', (match['homeYellowCards'] as num?)?.toInt() ?? 0, (match['awayYellowCards'] as num?)?.toInt() ?? 0, homeColor: Colors.amber, awayColor: Colors.amber),
                          _buildMiniStatBar('Thẻ đỏ', (match['homeRedCards'] as num?)?.toInt() ?? 0, (match['awayRedCards'] as num?)?.toInt() ?? 0, homeColor: Colors.redAccent, awayColor: Colors.redAccent),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
              ],

              // Mã mời và thống kê phòng
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
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                        border: Border.all(color: AppTheme.surfaceBorder),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(opt['label'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text('x${opt['odd']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
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
