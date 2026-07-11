import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/lobbies_provider.dart';
import 'package:dio/dio.dart';

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
            final int points = int.tryParse(_betPointsController.text) ?? 10;
            final double odd = (option['odd'] as num).toDouble();
            final int potentialPayout = (points * odd).floor();
            final int profit = potentialPayout - points;

            // Exposure math
            final int remainingExposure = market['exposureLimit'] - market['currentExposure'];
            final double exposureRatio = (market['currentExposure'] + potentialPayout) / market['exposureLimit'];

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

                    // Ô nhập cược
                    const Text('SỐ ĐIỂM CƯỢC', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _betPointsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        suffixText: "Điểm",
                        suffixStyle: const TextStyle(color: AppTheme.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (val) {
                        setModalState(() {});
                      },
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
                      onPressed: () async {
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
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 64),
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
      body: SingleChildScrollView(
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
            // Thông tin trận và nhà cái
            Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      matchDesc,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng quỹ phòng: ${room['totalPool']} pts',
                      style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Host: ${room['owner']['fullName']}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
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
                                        Text(opt['label'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                        const SizedBox(height: 2),
                                        Text('x${opt['odd']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
