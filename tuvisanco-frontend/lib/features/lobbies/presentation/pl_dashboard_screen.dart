import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/lobbies_provider.dart';

class MemberLeaderboardItem {
  final String userId;
  final String fullName;
  int wagered;
  int won;
  MemberLeaderboardItem({required this.userId, required this.fullName, this.wagered = 0, this.won = 0});
  int get netProfit => won - wagered;
}

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

    // Tính toán bảng xếp hạng thành viên lãi nhất phòng (Leaderboard phòng)
    final Map<String, MemberLeaderboardItem> leaderboardMap = {};
    for (var bet in placedBets) {
      final String uId = bet['userId']?.toString() ?? '';
      final String name = bet['user'] != null ? bet['user']['fullName'] : 'Ẩn danh';
      final int points = (bet['points'] as num).toInt();
      final double odd = (bet['odd'] as num).toDouble();
      final int payout = bet['result'] == 'WON' ? (points * odd).floor() : 0;

      if (!leaderboardMap.containsKey(uId)) {
        leaderboardMap[uId] = MemberLeaderboardItem(userId: uId, fullName: name);
      }
      leaderboardMap[uId]!.wagered += points;
      leaderboardMap[uId]!.won += payout;
    }

    final leaderboardList = leaderboardMap.values.toList()
      ..sort((a, b) => b.netProfit.compareTo(a.netProfit));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(isHouse ? 'Báo cáo Lãi/Lỗ Nhà Cái' : 'Báo cáo Lãi/Lỗ Cá Nhân'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tổng Quan', icon: Icon(Icons.analytics_outlined, size: 20)),
              Tab(text: 'Bảng Xếp Hạng', icon: Icon(Icons.emoji_events_outlined, size: 20)),
              Tab(text: 'Lịch Sử Cược', icon: Icon(Icons.history, size: 20)),
            ],
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Tổng quan lãi lỗ & Phân chia vốn
            _buildOverviewTab(context, isHouse, originalPool, currentPool, netPL, personalWagered, personalWon, personalPL, coOwners),
            // Tab 2: Bảng xếp hạng
            _buildLeaderboardTab(context, leaderboardList),
            // Tab 3: Lịch sử cược
            _buildBetHistoryTab(context, isHouse, placedBets, userBets),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, bool isHouse, int originalPool, int currentPool, int netPL, int personalWagered, int personalWon, int personalPL, List<dynamic> coOwners) {
    // List of colors for co-owners segments
    final colors = [
      Colors.deepPurpleAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.amber,
      Colors.pinkAccent,
      Colors.cyanAccent,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bảng Ledger tổng kết
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

          // PHÂN CHIA VỐN NHÀ CÁI (Chỉ hiển thị cho Nhà cái/Co-owner)
          if (isHouse && coOwners.isNotEmpty) ...[
            const Text(
              'CƠ CẤU CỔ PHẦN NHÀ CÁI',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Multi-segment progress bar for shares
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: Container(
                height: 10,
                width: double.infinity,
                color: Colors.white12,
                child: Row(
                  children: coOwners.map((co) {
                    final double ratio = (co['shareRatio'] as num).toDouble();
                    if (ratio <= 0) return const SizedBox.shrink();
                    final idx = coOwners.indexOf(co);
                    final color = colors[idx % colors.length];
                    return Expanded(
                      flex: (ratio * 100).round() > 0 ? (ratio * 100).round() : 1,
                      child: Container(color: color),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Co-owners list
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
                final color = colors[index % colors.length];

                return Card(
                  color: AppTheme.surfaceElevated,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Color Dot Badge
                        Container(
                          width: 8,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
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
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab(BuildContext context, List<MemberLeaderboardItem> leaderboardList) {
    if (leaderboardList.isEmpty) {
      return const Center(
        child: Text('Chưa có dữ liệu xếp hạng cược.', style: TextStyle(color: AppTheme.textDisabled)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboardList.length,
      itemBuilder: (context, index) {
        final item = leaderboardList[index];
        final rank = index + 1;
        final netProfit = item.netProfit;

        // Badge / Rank Icon
        Widget rankBadge;
        if (rank == 1) {
          rankBadge = const CircleAvatar(
            backgroundColor: Colors.amber,
            radius: 12,
            child: Text('1', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
          );
        } else if (rank == 2) {
          rankBadge = const CircleAvatar(
            backgroundColor: Colors.grey,
            radius: 12,
            child: Text('2', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
          );
        } else if (rank == 3) {
          rankBadge = const CircleAvatar(
            backgroundColor: Colors.brown,
            radius: 12,
            child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          );
        } else {
          rankBadge = CircleAvatar(
            backgroundColor: AppTheme.surfaceElevated,
            radius: 12,
            child: Text('$rank', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          );
        }

        return Card(
          color: AppTheme.surfaceElevated,
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                rankBadge,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng cược: ${item.wagered} pts | Thắng: ${item.won} pts',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      netProfit >= 0 ? '+$netProfit pts' : '$netProfit pts',
                      style: TextStyle(
                        color: netProfit >= 0 ? AppTheme.success : AppTheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Lãi/lỗ ròng',
                      style: TextStyle(color: AppTheme.textDisabled, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBetHistoryTab(BuildContext context, bool isHouse, List<dynamic> placedBets, List<dynamic> userBets) {
    final list = isHouse ? placedBets : userBets;
    if (list.isEmpty) {
      return const Center(
        child: Text('Chưa có lịch sử đặt cược nào.', style: TextStyle(color: AppTheme.textDisabled)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final bet = list[index];
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
