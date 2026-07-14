import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../data/match_model.dart';
import '../../../core/network/dio_client.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MatchModel? _match;
  bool _isLoading = true;
  String? _error;
  String _selectedSubTab = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: 1); // Select Thống kê by default
    _fetchMatchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatchDetails() async {
    try {
      final response = await dioClient.get('/matches/${widget.matchId}');
      if (response.statusCode == 200) {
        setState(() {
          _match = MatchModel.fromJson(response.data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Lỗi tải dữ liệu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Không thể kết nối máy chủ';
        _isLoading = false;
      });
    }
  }

  Widget _teamLogo(String? url, Color fallbackColor, {double size = 48}) {
    if (url == null || url.isEmpty) {
      return Icon(Icons.shield, color: fallbackColor, size: size);
    }
    final originalUrl = url.trim();
    final proxiedUrl = 'http://10.0.2.2:3000/matches/proxy/image?url=' + Uri.encodeComponent(originalUrl);
    
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F16),
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }
    
    if (_error != null || _match == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F16),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text(_error ?? 'Lỗi không xác định', style: const TextStyle(color: Colors.white))),
      );
    }

    final match = _match!;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      body: Column(
        children: [
          _buildHeader(match),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(match),
                _buildStatsTab(match),
                _buildEventsTab(match),
                _buildLineupTab(match),
                _buildH2HTab(match),
                _buildAITab(match),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(MatchModel match) {
    bool isNS = match.status == 'NS';
    bool isLive = match.status == 'LIVE';
    
    int h1Home = (match.homeScore / 2).ceil();
    int h1Away = (match.awayScore / 2).ceil();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2A5A), Color(0xFF0B0F16)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Column(
                    children: [
                      Text(match.leagueName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(DateFormat('dd-MM-yyyy HH:mm').format(match.startTime), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.star_border, color: Colors.white, size: 22), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.ios_share, color: Colors.white, size: 22), onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status
            Text(
              isLive ? "LIVE ${match.minuteElapsed}'" : (isNS ? "Chưa diễn ra" : "Đã kết thúc"),
              style: TextStyle(color: isLive ? Colors.greenAccent : Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            
            // Teams & Score
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Home Team
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(match.homeLogo, Colors.blueAccent, size: 50),
                        const SizedBox(height: 12),
                        Text(match.homeTeam, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  
                  // Score & Details
                  Column(
                    children: [
                      Text(
                        isNS ? '- : -' : '${match.homeScore} - ${match.awayScore}',
                        style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, height: 1),
                      ),
                      const SizedBox(height: 12),
                      if (!isNS) Text('HT $h1Home-$h1Away   FT ${match.homeScore}-${match.awayScore}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      if (!isNS) const SizedBox(height: 4),
                      if (!isNS) const Text('ET 0-0', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                  
                  // Away Team
                  Expanded(
                    child: Column(
                      children: [
                        _teamLogo(match.awayLogo, Colors.redAccent, size: 50),
                        const SizedBox(height: 12),
                        Text(match.awayTeam, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 3D Simulation Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B66F5).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.tv, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text('Mô phỏng', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161F2C),
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF3B66F5),
        labelColor: const Color(0xFF3B66F5),
        unselectedLabelColor: Colors.white70,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Thống kê'),
          Tab(text: 'Diễn biến'),
          Tab(text: 'Đội hình'),
          Tab(text: 'Đối đầu'),
          Tab(text: 'Dự đoán AI'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(MatchModel match) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _infoRow(Icons.calendar_today, 'Thời gian', DateFormat('HH:mm - dd/MM/yyyy').format(match.startTime)),
        _infoRow(Icons.stadium, 'Sân vận động', match.stadium ?? 'Đang cập nhật'),
        _infoRow(Icons.sports, 'Trọng tài', match.referee ?? 'Đang cập nhật'),
      ],
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF161F2C), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatsTab(MatchModel match) {
    if (match.status == 'NS') {
      return const Center(child: Text('Chưa có thống kê do trận đấu chưa diễn ra.', style: TextStyle(color: Colors.white54)));
    }
    
    final subTabs = ['Tất cả', 'Hiệp 1', 'Hiệp 2', 'Hiệp phụ'];
    
    // Mock Data based on total score / 10 to make it realistic
    int posHome = 45 + (match.homeScore * 2);
    if (posHome > 99) posHome = 99;
    int posAway = 100 - posHome;
    
    return Column(
      children: [
        // Sub Tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subTabs.map((tab) {
                bool isSelected = _selectedSubTab == tab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSubTab = tab),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF1E2736),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Stats List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildFoxScoreStatBar('Kiểm soát bóng', posHome, posAway, isPercentage: true),
              _buildFoxScoreStatBar('Tổng lần sút', match.homeShots, match.awayShots),
              _buildFoxScoreStatBar('Sút trúng mục tiêu', (match.homeShots * 0.4).ceil(), (match.awayShots * 0.4).ceil()),
              _buildFoxScoreStatBar('Sút trật mục tiêu', (match.homeShots * 0.6).floor(), (match.awayShots * 0.6).floor()),
              _buildFoxScoreStatBar('Chặn lần sút', 3, 3),
              _buildFoxScoreStatBar('Phạt góc', match.homeShots > 0 ? match.homeShots - 2 : 4, match.awayShots > 0 ? match.awayShots - 1 : 5),
              _buildFoxScoreStatBar('Việt vị', 1, 5),
              _buildFoxScoreStatBar('Phạm lỗi', 10, 8),
              _buildFoxScoreStatBar('Thẻ vàng', match.homeYellowCards, match.awayYellowCards),
              _buildFoxScoreStatBar('Thẻ đỏ', match.homeRedCards, match.awayRedCards),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFoxScoreStatBar(String title, int homeVal, int awayVal, {bool isPercentage = false}) {
    int total = homeVal + awayVal;
    if (total == 0) total = 1; // Prevent division by zero
    
    double homeRatio = homeVal / total;
    double awayRatio = awayVal / total;
    
    // FoxScore colors: Home Green (or Blue), Away Yellow (or Red). 
    // In dark theme: Home = GreenAccent, Away = Amber.
    Color homeColor = homeVal >= awayVal ? Colors.greenAccent : Colors.white24;
    Color awayColor = awayVal >= homeVal ? Colors.amber : Colors.white24;
    if (homeVal == awayVal) {
      homeColor = Colors.white24;
      awayColor = Colors.white24;
    }

    String homeStr = isPercentage ? '$homeVal%' : '$homeVal';
    String awayStr = isPercentage ? '$awayVal%' : '$awayVal';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(homeStr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(awayStr, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Home Bar
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: ((1 - homeRatio) * 100).toInt(),
                      child: Container(height: 6, color: Colors.white12),
                    ),
                    Expanded(
                      flex: (homeRatio * 100).toInt(),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: homeColor,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), bottomLeft: Radius.circular(3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Away Bar
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: (awayRatio * 100).toInt(),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: awayColor,
                          borderRadius: const BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - awayRatio) * 100).toInt(),
                      child: Container(height: 6, color: Colors.white12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(MatchModel match) {
    return const Center(child: Text('Đang cập nhật diễn biến trận đấu...', style: TextStyle(color: Colors.white54)));
  }

  Widget _buildLineupTab(MatchModel match) {
    if (match.lineupHome == null || match.lineupAway == null) {
      return const Center(child: Text('Chưa có dữ liệu đội hình cho trận đấu này.', style: TextStyle(color: Colors.white54)));
    }

    final homeXi = match.lineupHome!['starting_xi'] as List<dynamic>? ?? [];
    final awayXi = match.lineupAway!['starting_xi'] as List<dynamic>? ?? [];

    if (homeXi.isEmpty && awayXi.isEmpty) {
      return const Center(child: Text('Đội hình xuất phát chưa được công bố.', style: TextStyle(color: Colors.white54)));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: homeXi.length,
            itemBuilder: (context, i) {
              final player = homeXi[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blueAccent.withOpacity(0.2),
                      child: Text('${player['jersey_number'] ?? '-'}', style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(player['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(player['position'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(width: 1, color: Colors.white12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: awayXi.length,
            itemBuilder: (context, i) {
              final player = awayXi[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(player['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(player['position'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      child: Text('${player['jersey_number'] ?? '-'}', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildH2HTab(MatchModel match) {
    if (match.h2hHistory == null || match.h2hHistory!.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu lịch sử đối đầu.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: match.h2hHistory!.length,
      itemBuilder: (context, index) {
        final h2h = match.h2hHistory![index];
        final date = DateTime.parse(h2h['date']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF161F2C), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(h2h['homeTeam'], textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 14))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('${h2h['homeScore']} - ${h2h['awayScore']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Text(h2h['awayTeam'], textAlign: TextAlign.left, style: const TextStyle(color: Colors.white, fontSize: 14))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAITab(MatchModel match) {
    if (match.aiAnalysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text('Hệ thống AI chưa phân tích trận đấu này.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B66F5)),
              child: const Text('Yêu cầu AI phân tích', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('TỶ LỆ DỰ ĐOÁN TỪ THIÊN CƠ AI', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _aiProbCard(match.homeTeam, match.aiWinProb ?? 0.33, Colors.blueAccent),
            const SizedBox(width: 12),
            _aiProbCard('Hòa', match.aiDrawProb ?? 0.33, Colors.grey),
            const SizedBox(width: 12),
            _aiProbCard(match.awayTeam, match.aiLossProb ?? 0.34, Colors.redAccent),
          ],
        ),
        const SizedBox(height: 32),
        const Text('NHẬN ĐỊNH CHI TIẾT', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF161F2C), borderRadius: BorderRadius.circular(12)),
          child: Text(
            match.aiAnalysis ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }
  
  Widget _aiProbCard(String title, double prob, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${(prob * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
