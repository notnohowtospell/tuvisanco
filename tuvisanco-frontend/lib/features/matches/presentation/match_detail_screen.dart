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

  // Chat state
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [
    {'sender': 'Hệ thống', 'text': 'Phòng trò chuyện trận đấu đã mở. Mọi người bắt đầu thảo luận nhé!', 'isMe': false, 'time': DateTime.now()}
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this, initialIndex: 0); 
    _fetchMatchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatchDetails() async {
    try {
      print('REQUESTING: /matches/${widget.matchId} with baseUrl: ${dioClient.options.baseUrl}');
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
    } catch (e, stack) {
      print('LỖI TẢI CHI TIẾT TRẬN ĐẤU: $e');
      print(stack);
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
    final proxiedUrl = '$baseUrl/matches/proxy/image?url=${Uri.encodeComponent(originalUrl)}';
    
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
                _buildChatTab(match),
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
          Tab(text: 'Trò chuyện'),
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

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({
        'sender': 'Bạn',
        'text': text,
        'isMe': true,
        'time': DateTime.now(),
      });
    });
    _chatController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Mock bot reply
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final replies = [
        'Trận này chắc tài rồi anh em ơi',
        'Cố lên đội nhà!',
        'Trọng tài bắt chán quá',
        'Thấy đá cũng bình thường mà',
      ];
      setState(() {
        _chatMessages.add({
          'sender': 'Đạo hữu ẩn danh',
          'text': replies[DateTime.now().millisecond % replies.length],
          'isMe': false,
          'time': DateTime.now(),
        });
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Widget _buildChatTab(MatchModel match) {
    return Column(
      children: [
        // Chat List
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              final isMe = msg['isMe'] as bool;
              final isSystem = msg['sender'] == 'Hệ thống';
              
              if (isSystem) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg['text'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                );
              }

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(msg['sender'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF3B66F5) : const Color(0xFF1E2736),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                        ),
                        child: Text(msg['text'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Input Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF161F2C),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F16),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFF3B66F5), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    
    final stats = match.teamStats ?? {};
    
    int posHome = stats['possession']?['home'] ?? 0;
    int posAway = stats['possession']?['away'] ?? 0;
    int homeShots = stats['shots']?['home'] ?? match.homeShots;
    int awayShots = stats['shots']?['away'] ?? match.awayShots;
    int homeShotsOnTarget = stats['shots_on_target']?['home'] ?? 0;
    int awayShotsOnTarget = stats['shots_on_target']?['away'] ?? 0;
    int homeShotsOffTarget = stats['shots_off_target']?['home'] ?? 0;
    int awayShotsOffTarget = stats['shots_off_target']?['away'] ?? 0;
    int homeBlocked = stats['blocked_shots']?['home'] ?? 0;
    int awayBlocked = stats['blocked_shots']?['away'] ?? 0;
    int homeCorners = stats['corners']?['home'] ?? 0;
    int awayCorners = stats['corners']?['away'] ?? 0;
    int homeOffsides = stats['offsides']?['home'] ?? 0;
    int awayOffsides = stats['offsides']?['away'] ?? 0;
    int homeFouls = stats['fouls']?['home'] ?? 0;
    int awayFouls = stats['fouls']?['away'] ?? 0;
    
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
              _buildFoxScoreStatBar('Tổng lần sút', homeShots, awayShots),
              _buildFoxScoreStatBar('Sút trúng mục tiêu', homeShotsOnTarget, awayShotsOnTarget),
              _buildFoxScoreStatBar('Sút trật mục tiêu', homeShotsOffTarget, awayShotsOffTarget),
              _buildFoxScoreStatBar('Chặn lần sút', homeBlocked, awayBlocked),
              _buildFoxScoreStatBar('Phạt góc', homeCorners, awayCorners),
              _buildFoxScoreStatBar('Việt vị', homeOffsides, awayOffsides),
              _buildFoxScoreStatBar('Phạm lỗi', homeFouls, awayFouls),
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
    if (match.status == 'NS') {
      return const Center(child: Text('Trận đấu chưa diễn ra.', style: TextStyle(color: Colors.white54)));
    }
    
    final events = match.events;
    if (events.isEmpty) {
      return const Center(child: Text('Chưa có sự kiện nào được ghi nhận.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final bool isHome = event['team'] == 'home';
        final int minute = event['minute'] ?? 0;
        final String type = event['type'] ?? '';
        final String player = event['player'] ?? '';

        Widget icon;
        if (type == 'goal') {
          icon = const Icon(Icons.sports_soccer, color: Colors.white, size: 16);
        } else if (type == 'yellow_card') {
          icon = Container(width: 12, height: 16, color: Colors.yellow, margin: const EdgeInsets.all(2));
        } else if (type == 'red_card') {
          icon = Container(width: 12, height: 16, color: Colors.red, margin: const EdgeInsets.all(2));
        } else {
          icon = const Icon(Icons.info, color: Colors.white54, size: 16);
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Home Side
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  alignment: Alignment.topRight,
                  child: isHome ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(player, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      icon,
                    ],
                  ) : null,
                ),
              ),
              
              // Center Line & Time
              SizedBox(
                width: 50,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(width: 1, color: Colors.white24), // Full height line
                    Container(
                      margin: const EdgeInsets.only(top: 0),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFF1E2736), border: Border.all(color: Colors.white24), shape: BoxShape.circle),
                      child: Text('$minute\'', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  ]
                )
              ),
              
              // Away Side
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  alignment: Alignment.topLeft,
                  child: !isHome ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Text(player, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ) : null,
                ),
              ),
            ]
          )
        );
      },
    );
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

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 800, // Fixed height for pitch
        child: LineupPitchView(match: match),
      ),
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

// --- NEW WIDGETS FOR LINEUP PITCH VIEW ---

class LineupPitchView extends StatelessWidget {
  final MatchModel match;

  const LineupPitchView({Key? key, required this.match}) : super(key: key);

  List<List<dynamic>> _parseFormation(List<dynamic> xi, String? formationStr, bool isHome) {
    if (xi.isEmpty) return [];
    
    // Default fallback if formation string is missing
    if (formationStr == null || formationStr.isEmpty) {
      final g = xi.where((p) => p['position'] == 'G').toList();
      final d = xi.where((p) => p['position'] == 'D').toList();
      final m = xi.where((p) => p['position'] == 'M').toList();
      final f = xi.where((p) => p['position'] == 'F').toList();
      
      var rows = [g, d, m, f];
      rows.removeWhere((r) => r.isEmpty);
      if (!isHome) rows = rows.reversed.toList();
      return rows;
    }

    final parts = formationStr.split('-').map((e) => int.tryParse(e) ?? 0).toList();
    List<List<dynamic>> rows = [];
    
    // First row is ALWAYS goalkeeper (1)
    rows.add([xi.first]);
    
    int currentIndex = 1;
    for (int count in parts) {
      if (currentIndex + count <= xi.length) {
        rows.add(xi.sublist(currentIndex, currentIndex + count));
        currentIndex += count;
      }
    }
    
    if (currentIndex < xi.length) {
       rows.add(xi.sublist(currentIndex));
    }
    
    if (!isHome) rows = rows.reversed.toList();
    return rows;
  }

  Widget _buildPlayerWidget(dynamic player, bool isHome) {
    final String name = player['name'] ?? '';
    final String num = '${player['jersey_number'] ?? '-'}';
    
    List<String> parts = name.split(' ');
    String shortName = name;
    if (parts.length > 1) {
       shortName = '${parts[0][0]}. ${parts.last}';
    }

    final logoUrl = isHome ? match.homeLogo : match.awayLogo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
         Stack(
           children: [
             CircleAvatar(
               radius: 18,
               backgroundColor: Colors.white,
               child: ClipOval(
                  child: logoUrl != null 
                    ? Image.network(logoUrl, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.flag, color: Colors.grey))
                    : const Icon(Icons.flag, color: Colors.grey),
               ),
             ),
             Positioned(
               bottom: 0,
               right: -4,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                 decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(num, style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
               )
             )
           ]
         ),
         const SizedBox(height: 4),
         Container(
           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
           decoration: BoxDecoration(
             color: Colors.black45,
             borderRadius: BorderRadius.circular(4),
           ),
           child: Text(shortName, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
         )
      ],
    );
  }

  Widget _buildPlayerRow(List<dynamic> rowPlayers, bool isHome) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: rowPlayers.map((p) => _buildPlayerWidget(p, isHome)).toList(),
    );
  }

  Widget _buildFormationHeader(String? logoUrl, String teamName, String? formation, bool isHome) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (logoUrl != null) Image.network(logoUrl, width: 24, height: 24, errorBuilder: (_,__,___) => const SizedBox()),
              if (logoUrl != null) const SizedBox(width: 8),
              Text(teamName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.shade800, borderRadius: BorderRadius.circular(12)),
            child: Text(formation ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeXi = match.lineupHome?['starting_xi'] as List<dynamic>? ?? [];
    final awayXi = match.lineupAway?['starting_xi'] as List<dynamic>? ?? [];
    
    final homeRows = _parseFormation(homeXi, match.lineupHome?['formation'], true);
    final awayRows = _parseFormation(awayXi, match.lineupAway?['formation'], false);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF4C7D52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Stack(
         children: [
            Positioned.fill(child: CustomPaint(painter: PitchPainter())),
            Column(
               children: [
                  _buildFormationHeader(match.homeLogo, match.homeTeam, match.lineupHome?['formation'], true),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: homeRows.map((row) => _buildPlayerRow(row, true)).toList(),
                    ),
                  ),
                  const SizedBox(height: 10), // Halfway space
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: awayRows.map((row) => _buildPlayerRow(row, false)).toList(),
                    ),
                  ),
                  _buildFormationHeader(match.awayLogo, match.awayTeam, match.lineupAway?['formation'], false),
               ]
            )
         ]
      )
    );
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Halfway line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    
    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.15, paint);
    
    // Center dot
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke; // Reset
    
    // Top penalty box
    canvas.drawRect(Rect.fromLTWH(size.width * 0.25, 0, size.width * 0.5, size.height * 0.15), paint);
    // Top goal box
    canvas.drawRect(Rect.fromLTWH(size.width * 0.38, 0, size.width * 0.24, size.height * 0.06), paint);
    // Top penalty arc
    canvas.drawArc(
        Rect.fromLTWH(size.width * 0.4, size.height * 0.1, size.width * 0.2, size.height * 0.1),
        0, 3.14159, false, paint);
        
    // Bottom penalty box
    canvas.drawRect(Rect.fromLTWH(size.width * 0.25, size.height * 0.85, size.width * 0.5, size.height * 0.15), paint);
    // Bottom goal box
    canvas.drawRect(Rect.fromLTWH(size.width * 0.38, size.height * 0.94, size.width * 0.24, size.height * 0.06), paint);
    // Bottom penalty arc
    canvas.drawArc(
        Rect.fromLTWH(size.width * 0.4, size.height * 0.8, size.width * 0.2, size.height * 0.1),
        3.14159, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
