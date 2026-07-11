import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
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

    final String currentUserId = ref.watch(authProvider).userId ?? '';
    final coOwners = room['coOwners'] as List<dynamic>? ?? [];
    
    // Kiểm tra xem user hiện tại là Nhà cái chính (Owner) hoặc đồng chủ phòng (Co-owner) hay không
    final bool isHouse = room['ownerId'] == currentUserId || 
        coOwners.any((co) => co['userId'] == currentUserId && (co['contribution'] as num) > 0);

    // Tính toán lãi lỗ tổng của cả phòng cược (Dành cho nhà cái)
    int originalPool = 0;
    for (var co in coOwners) {
      originalPool += (co['contribution'] as num).toInt();
    }
    final int currentPool = (room['totalPool'] as num).toInt();
    final int netPL = currentPool - originalPool;

    // Tính toán cược cá nhân (Dành cho người chơi thường)
    final placedBets = room['placedBets'] as List<dynamic>? ?? [];
    final userBets = placedBets.where((bet) => bet['userId'] == currentUserId).toList();
    
    int personalWagered = 0;
    int personalWon = 0;
    for (var bet in userBets) {
      personalWagered += (bet['points'] as num).toInt();
      if (bet['result'] == 'WON') {
        personalWon += ((bet['points'] as num) * (bet['odd'] as num)).floor();
      }
    }
    final int personalPL = personalWon - personalWagered;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isHouse ? 'Báo cáo Lãi/Lỗ Nhà Cái' : 'Báo cáo Lãi/Lỗ Cá Nhân'),
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
            // 1. BẢNG LEDGER TỔNG KẾT
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
                    Text(
                      isHouse ? 'TỔNG KẾT QUỸ NHÀ CÁI (HOUSE)' : 'TỔNG KẾT CƯỢC CÁ NHÂN',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (isHouse) ...[
                      _buildLedgerRow('Vốn đóng góp ban đầu:', '$originalPool pts'),
                      _buildLedgerRow('Quỹ nhà cái hiện tại:', '$currentPool pts'),
                    ] else ...[
                      _buildLedgerRow('Tổng số điểm đã cược:', '$personalWagered pts'),
                      _buildLedgerRow('Tổng số điểm thắng nhận về:', '$personalWon pts'),
                    ],
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
                          isHouse 
                              ? (netPL >= 0 ? '+${netPL} pts' : '${netPL} pts')
                              : (personalPL >= 0 ? '+${personalPL} pts' : '${personalPL} pts'),
                          style: TextStyle(
                            color: (isHouse ? netPL : personalPL) >= 0 ? AppTheme.success : AppTheme.error,
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

            // 2. TỶ LỆ PHÂN CHIA VỐN NHÀ CÁI (Chỉ hiển thị cho Nhà cái/Co-owner)
            if (isHouse) ...[
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
            ],

            // 3. DANH SÁCH ĐƠN CƯỢC
            Text(
              isHouse ? 'TÌNH HÌNH ĐẶT CƯỢC CỦA THÀNH VIÊN' : 'LỊCH SỬ ĐẶT CƯỢC CỦA BẠN',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Lấy danh sách cược tùy theo phân quyền (Nhà cái xem hết, Con bạc chỉ xem của mình)
            if (isHouse && placedBets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('Chưa có thành viên nào đặt cược.', style: TextStyle(color: AppTheme.textDisabled)),
                ),
              )
            else if (!isHouse && userBets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text('Bạn chưa đặt cược nào trong phòng này.', style: TextStyle(color: AppTheme.textDisabled)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: isHouse ? placedBets.length : userBets.length,
                itemBuilder: (context, index) {
                  final bet = isHouse ? placedBets[index] : userBets[index];
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
                              if (isHouse)
                                Text(username, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                              else
                                Text(bet['market'] != null ? bet['market']['title'] : 'Kèo cược', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
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
