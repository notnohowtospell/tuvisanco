import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../data/lobbies_provider.dart';

class PLDashboardScreen extends ConsumerWidget {
  final String roomCode;
  const PLDashboardScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lobbiesProvider);
    final room = state.currentRoomDetails;

    if (room == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // Tính toán lãi lỗ tổng của cả phòng cược
    // (VD: tổng điểm ban đầu của nhà cái so với tổng điểm hiện tại sau cược)
    final coOwners = room['coOwners'] as List<dynamic>;
    int originalPool = 0;
    for (var co in coOwners) {
      originalPool += (co['contribution'] as num).toInt();
    }
    
    final int currentPool = (room['totalPool'] as num).toInt();
    final int netPL = currentPool - originalPool;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Báo cáo Lãi/Lỗ P&L'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bảng tổng hợp lãi lỗ quỹ nhà cái (House Pool)
            Card(
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: const BorderSide(color: AppTheme.surfaceBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỔNG KẾT QUỸ NHÀ CÁI (HOUSE)',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildLedgerRow('Vốn đóng góp ban đầu:', '$originalPool pts'),
                    _buildLedgerRow('Quỹ nhà cái hiện tại:', '$currentPool pts'),
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.surfaceBorder, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lợi nhuận ròng (P&L):',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          netPL >= 0 ? '+${netPL} pts' : '${netPL} pts',
                          style: TextStyle(
                            color: netPL >= 0 ? AppTheme.success : AppTheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tỷ lệ phân chia đồng chủ phòng (Co-owners Payouts)
            const Text(
              'PHÂN CHIA VỐN & LỢI NHUẬN NHÀ CÁI',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: coOwners.length,
              itemBuilder: (context, index) {
                final co = coOwners[index];
                final double ratio = (co['shareRatio'] as num).toDouble();
                final int original = co['contribution'];
                final int currentShare = (currentPool * ratio).floor();
                final int coPL = currentShare - original;

                return Card(
                  color: AppTheme.surfaceElevated,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              co['user']['fullName'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cổ phần: ${(ratio * 100).toStringAsFixed(1)}% (Góp: $original pts)',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$currentShare pts',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              coPL >= 0 ? '+$coPL pts' : '$coPL pts',
                              style: TextStyle(color: coPL >= 0 ? AppTheme.success : AppTheme.error, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Danh sách người chơi đặt cược (Members Bets Summary)
            const Text(
              'TÌNH HÌNH ĐẶT CƯỢC CỦA THÀNH VIÊN',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (room['placedBets'] == null || room['placedBets'].isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('Chưa có thành viên nào đặt cược.', style: TextStyle(color: AppTheme.textDisabled)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: room['placedBets'].length,
                itemBuilder: (context, index) {
                  final bet = room['placedBets'][index];
                  final String username = bet['user'] != null ? bet['user']['fullName'] : "Ẩn danh";
                  final int points = bet['points'];
                  final double odd = (bet['odd'] as num).toDouble();
                  final String result = bet['result']; // WON, LOST, PENDING
                  
                  Color resultColor = AppTheme.neutral;
                  String resultText = "Đang chờ";
                  if (result == 'WON') {
                    resultColor = AppTheme.success;
                    resultText = "Thắng cược";
                  } else if (result == 'LOST') {
                    resultColor = AppTheme.error;
                    resultText = "Thua cược";
                  }

                  return Card(
                    color: AppTheme.surface,
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                'Cược: $points pts (Tỷ lệ: x$odd)',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: resultColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Text(
                              resultText,
                              style: TextStyle(color: resultColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildLedgerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
