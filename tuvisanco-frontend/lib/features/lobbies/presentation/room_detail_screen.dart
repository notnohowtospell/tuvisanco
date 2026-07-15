import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/lobbies_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';

// Lưu trữ danh sách mã cược đã hiển thị thông báo để tránh lặp lại
final Set<String> _notifiedBetIds = {};

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomCode;
  const RoomDetailScreen({super.key, required this.roomCode});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  final _betPointsController = TextEditingController(text: '10');
  
  bool _showWonBanner = false;
  int _wonPointsSum = 0;
  Timer? _bannerTimer;
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

  Widget _teamLogo(String? url, Color fallbackColor, {double size = 24}) {
    if (url == null || url.isEmpty) {
      return Icon(Icons.shield, color: fallbackColor, size: size);
    }
    final originalUrl = url.trim();
    final proxiedUrl = '$apiBaseUrl/matches/proxy/image?url=' + Uri.encodeComponent(originalUrl);

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

  @override
  void dispose() {
    _betPointsController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _openBetSlip(dynamic room, dynamic market, dynamic option) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildQuickBetChip(String label, int val, int maxLimit, {bool isAllIn = false}) {
              return InkWell(
                onTap: () {
                  setModalState(() {
                    if (isAllIn) {
                      _betPointsController.text = val.toString();
                    } else {
                      int current = int.tryParse(_betPointsController.text) ?? 10;
                      int newVal = (current + val).clamp(10, maxLimit);
                      _betPointsController.text = newVal.toString();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }

            final int points = int.tryParse(_betPointsController.text) ?? 10;
            final double odd = (option['odd'] as num).toDouble();
            final int potentialPayout = (points * odd).floor();
            final int profit = potentialPayout - points;

            // Exposure math
            final int remainingExposure = market['exposureLimit'] - market['currentExposure'];
            final double exposureRatio = (market['currentExposure'] + potentialPayout) / market['exposureLimit'];

            // Tính toán giới hạn cược tối đa động
            final int membersCount = (room['members'] as List?)?.length ?? 0;
            final int totalMembers = (membersCount + 1) > 2 ? (membersCount + 1) : 2;
            final int exposureLimit = (market['exposureLimit'] as num).toInt();
            final int maxBetLimit = (exposureLimit ~/ totalMembers) > 20 ? (exposureLimit ~/ totalMembers) : 20;
            final bool isBetInvalid = points < 10 || points > maxBetLimit;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glassmorphism
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 24),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withOpacity(0.85),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMd),
                    topRight: Radius.circular(AppTheme.radiusMd),
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textDisabled.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Phiếu Đặt Cược (Bet Slip)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Kèo đã chọn
                    Text(
                      market['title'],
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lựa chọn: ${option['label']} (Odds: x$odd)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // Ô nhập cược và Slider cược nhanh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SỐ ĐIỂM CƯỢC', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        Text(
                          'Giới hạn: 10 - $maxBetLimit pts',
                          style: const TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _betPointsController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              onChanged: (val) {
                                setModalState(() {});
                              },
                            ),
                          ),
                          const Text(
                            'pts',
                            style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Thanh trượt cược nhanh (Slider)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: AppTheme.surfaceElevated,
                        thumbColor: AppTheme.warning,
                        overlayColor: AppTheme.warning.withOpacity(0.2),
                        valueIndicatorColor: AppTheme.primary,
                        valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      child: Slider(
                        value: points.toDouble().clamp(10.0, maxBetLimit.toDouble()),
                        min: 10.0,
                        max: maxBetLimit.toDouble(),
                        divisions: maxBetLimit > 10 ? (maxBetLimit - 10) : 1,
                        onChanged: (val) {
                          setModalState(() {
                            _betPointsController.text = val.round().toString();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Nút chọn nhanh (Chips)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildQuickBetChip('+10', 10, maxBetLimit),
                        buildQuickBetChip('+50', 50, maxBetLimit),
                        buildQuickBetChip('+100', 100, maxBetLimit),
                        buildQuickBetChip('All-in', maxBetLimit, maxBetLimit, isAllIn: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isBetInvalid)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          points < 10 
                              ? 'Mức cược tối thiểu là 10 pts' 
                              : 'Vượt quá hạn mức tối đa cho phép là $maxBetLimit pts',
                          style: const TextStyle(color: AppTheme.error, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Tính toán thưởng tiềm năng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Thắng nhận về (Payout):', style: TextStyle(color: AppTheme.textSecondary)),
                        Text('$potentialPayout pts', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lợi nhuận ròng:', style: TextStyle(color: AppTheme.textSecondary)),
                        Text('+$profit pts', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Exposure limit meter
                    const Text('Hạn mức rủi ro còn lại của nhà cái:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      child: LinearProgressIndicator(
                        value: exposureRatio.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.surfaceElevated,
                        color: exposureRatio > 0.8 ? AppTheme.error : AppTheme.success,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Còn lại: $remainingExposure pts (Exposure Limit: ${market['exposureLimit']} pts)',
                      style: const TextStyle(color: AppTheme.textDisabled, fontSize: 11),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: isBetInvalid ? null : () async {
                        final user = ref.read(authProvider);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        if (points > user.points) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Số dư điểm không đủ.'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        try {
                          await ref.read(lobbiesProvider.notifier).placeBet(
                            userId: user.userId!,
                            roomId: room['id'],
                            marketId: market['id'],
                            optionId: option['id'],
                            points: points,
                            code: widget.roomCode,
                          );
                          
                          // Mở màn hình ăn mừng thành công (Bet Confirmed)
                          _showBetSuccessDialog(option['label'], odd, points, potentialPayout);
                        } catch (e) {
                          String message = e.toString();
                          if (e is DioException) {
                            final serverMsg = e.response?.data?['message'];
                            if (serverMsg != null) {
                              message = serverMsg is List ? serverMsg.join(', ') : serverMsg.toString();
                            }
                          }
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Đặt cược thất bại: $message'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Text('Xác nhận đặt cược'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBetSuccessDialog(String label, double odd, int points, int payout) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Đặt Cược Thành Công!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.surfaceBorder, height: 1),
                const SizedBox(height: 16),
                _buildConfirmRow('Lựa chọn:', label),
                _buildConfirmRow('Tỷ lệ cược:', 'x$odd'),
                _buildConfirmRow('Số điểm đặt:', '$points pts'),
                _buildConfirmRow('Thưởng tối đa:', '$payout pts'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _refreshDetails();
                  },
                  child: const Text('Quay lại phòng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi trạng thái phòng cược để hiển thị Banner chúc mừng thắng cuộc 1 lần duy nhất
    ref.listen(lobbiesProvider, (previous, next) {
      final roomDetails = next.currentRoomDetails;
      if (roomDetails != null) {
        final String currentUserId = ref.read(authProvider).userId ?? '';
        final placedBets = roomDetails['placedBets'] as List<dynamic>? ?? [];
        
        // Tìm các đơn cược đã THẮNG (WON) mà CHƯA từng được hiển thị thông báo chúc mừng
        final newWonBets = placedBets.where((bet) => 
          bet['userId'] == currentUserId && 
          bet['result'] == 'WON' &&
          !_notifiedBetIds.contains(bet['id'].toString())
        ).toList();

        if (newWonBets.isNotEmpty) {
          final int pointsWon = newWonBets.fold<int>(0, (sum, bet) => 
            sum + ((bet['points'] as num) * (bet['odd'] as num)).floor() - (bet['points'] as num).toInt()
          );

          // Đánh dấu đã hiển thị
          _notifiedBetIds.addAll(newWonBets.map((b) => b['id'].toString()));

          setState(() {
            _showWonBanner = true;
            _wonPointsSum = pointsWon;
          });

          // Tự động đóng banner sau 6 giây
          _bannerTimer?.cancel();
          _bannerTimer = Timer(const Duration(seconds: 6), () {
            if (mounted) {
              setState(() {
                _showWonBanner = false;
              });
            }
          });
        }
      }
    });

    final state = ref.watch(lobbiesProvider);
    final room = state.currentRoomDetails;

    if (state.isLoading || room == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final String matchDesc = room['match'] != null
        ? "${room['match']['homeTeam']} vs ${room['match']['awayTeam']}"
        : "Đang tải trận đấu...";

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(room['name']),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshDetails,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
            onPressed: () => context.push('/rooms/pl/${widget.roomCode}'),
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
              if (_showWonBanner) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.greenAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🎉 Chúc mừng! Bạn đã thắng cược!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bạn đã thắng $_wonPointsSum điểm từ các cược đã quyết toán trong phòng này!',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.greenAccent, size: 18),
                        onPressed: () {
                          setState(() {
                            _showWonBanner = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
              
              // Thông tin trận và nhà cái (Cao Cấp)
              () {
                final match = room['match'];
                final DateTime? matchTime = match != null && match['startTime'] != null 
                    ? DateTime.tryParse(match['startTime'].toString()) 
                    : null;

                if (match != null) {
                  return Container(
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
                        const Divider(color: Colors.white10, height: 1),
                        // Footer: Pool and check status
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tổng quỹ: ${room['totalPool']} pts',
                                style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/match/detail/${match['id']}'),
                                child: Row(
                                  children: const [
                                    Text('Chi tiết trận', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 2),
                                    Icon(Icons.chevron_right, color: AppTheme.primary, size: 14),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Card(
                    color: AppTheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(matchDesc, style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }
              }(),

              // Bảng thông số trận đấu trực tiếp (Live Stats Accordion)
              () {
                final match = room['match'];
                if (match != null && match['status'] != 'NS') {
                  return Column(
                    children: [
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
                  );
                }
                return const SizedBox.shrink();
              }(),

              const SizedBox(height: 24),

              const Text(
                'KÈO ĐANG MỞ CƯỢC (OPEN)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (room['markets'] == null || room['markets'].isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('Chưa có kèo nào mở cược.', style: TextStyle(color: AppTheme.textDisabled)),
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

                    final placedBets = room['placedBets'] as List<dynamic>? ?? [];
                    final Map<String, int> optionBetSums = {};
                    int totalMarketBets = 0;
                    for (var opt in options) {
                      final optId = opt['id'].toString();
                      final int sum = placedBets
                          .where((b) => b['marketId'].toString() == market['id'].toString() && b['optionId'].toString() == optId)
                          .fold<int>(0, (prev, element) => prev + (element['points'] as num).toInt());
                      optionBetSums[optId] = sum;
                      totalMarketBets += sum;
                    }

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
                                if (market['category'] == 'FUN_BET')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentPink.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                    ),
                                    child: const Text(
                                      'KÈO VUI',
                                      style: TextStyle(color: AppTheme.accentPink, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: options.map((opt) {
                                final bool isHomeTeamOption = room['match'] != null &&
                                    opt['label'].toString().trim().toLowerCase() == room['match']['homeTeam'].toString().trim().toLowerCase();
                                final bool isAwayTeamOption = room['match'] != null &&
                                    opt['label'].toString().trim().toLowerCase() == room['match']['awayTeam'].toString().trim().toLowerCase();

                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed: market['status'] != 'OPEN'
                                          ? null
                                          : () => _openBetSlip(room, market, opt),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.surface,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        minimumSize: const Size(double.infinity, 44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                          side: const BorderSide(color: AppTheme.surfaceBorder),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (isHomeTeamOption) ...[
                                                _teamLogo(room['match']['homeLogo'], Colors.blue, size: 16),
                                                const SizedBox(width: 4),
                                              ] else if (isAwayTeamOption) ...[
                                                _teamLogo(room['match']['awayLogo'], Colors.red, size: 16),
                                                const SizedBox(width: 4),
                                              ],
                                              Flexible(
                                                child: Text(
                                                  opt['label'],
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('x${opt['odd']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            // Phân bổ lượng cược trong phòng (Bet Distribution)
                            if (totalMarketBets > 0) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Phân bổ lượng cược trong phòng:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  Text('Tổng: $totalMarketBets pts', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Dual progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                child: Container(
                                  height: 6,
                                  width: double.infinity,
                                  color: Colors.white12,
                                  child: Row(
                                    children: options.where((opt) => (optionBetSums[opt['id'].toString()] ?? 0) > 0).map((opt) {
                                      final optId = opt['id'].toString();
                                      final sum = optionBetSums[optId] ?? 0;
                                      final idx = options.indexOf(opt);
                                      final color = idx == 0 ? Colors.greenAccent : (idx == 1 ? Colors.amber : Colors.blueAccent);
                                      return Expanded(
                                        flex: sum,
                                        child: Container(color: color),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Text labels
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: options.map((opt) {
                                  final optId = opt['id'].toString();
                                  final sum = optionBetSums[optId] ?? 0;
                                  final percent = totalMarketBets > 0 ? (sum * 100 / totalMarketBets).round() : 0;
                                  final idx = options.indexOf(opt);
                                  final color = idx == 0 ? Colors.greenAccent : (idx == 1 ? Colors.amber : Colors.blueAccent);
                                  return Text(
                                    '${opt['label']}: $percent% ($sum pts)',
                                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
