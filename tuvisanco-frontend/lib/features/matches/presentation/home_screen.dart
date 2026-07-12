import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/match_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedTab = 'Tất cả';
  Future<List<MatchModel>>? _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _fetchMatches();
  }

  Future<List<MatchModel>> _fetchMatches() async {
    try {
      final response = await dioClient.get('/matches');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => MatchModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => setState(() { _matchesFuture = _fetchMatches(); }),
        child: FutureBuilder<List<MatchModel>>(
          future: _matchesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
              );
            }
            final matches = snapshot.data ?? [];
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabs(),
                  _buildBanner(authState.username ?? 'Đạo hữu'),
                  
                  _buildSectionHeader('✨ Đại Trận Tiêu Điểm', showSeeAll: true),
                  _buildFeaturedSection(matches),

                  _buildMatchGroups(matches),
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF161F2C),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Image.asset('assets/images/Logo.png', errorBuilder: (c, e, s) => const Icon(Icons.stars, color: Colors.blueAccent)),
      ),
      title: const Text('Tử Vi Sân Cỏ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      actions: [
        IconButton(
          icon: const Icon(Icons.sync, color: Colors.blueAccent),
          tooltip: 'Lấy Thiên Cơ',
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang đồng bộ từ World Cup...')));
            try {
              await dioClient.post('/matches/sync');
              setState(() { _matchesFuture = _fetchMatches(); });
            } catch (e) {
              debugPrint('Sync failed: $e');
            }
          },
        ),
        IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white70), onPressed: () {}),
      ],
    );
  }

  Widget _buildTabs() {
    final tabs = ['Tất cả', '● Live', 'Kết thúc', 'Sắp diễn ra'];
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: tabs.length + 1,
        itemBuilder: (context, index) {
          if (index == tabs.length) return _buildIconBtn(Icons.calendar_month);
          final tab = tabs[index];
          bool isSelected = _selectedTab == tab.replaceAll('● ', '');
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = tab.replaceAll('● ', '')),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B66F5).withOpacity(0.15) : const Color(0xFF1E2736),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFF3B66F5) : Colors.transparent),
              ),
              child: Center(child: Text(tab, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF1E2736), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white70, size: 18),
    );
  }

  Widget _buildBanner(String name) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF161F2C), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THIÊN CƠ HIỆN HỮU', style: TextStyle(color: Color(0xFF4A5664), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text('Chào $name,\nxem quẻ hôm nay?', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 12),
                _badge('🔮 Vận may: 88%'),
              ],
            ),
          ),
          const Opacity(opacity: 0.1, child: Icon(Icons.explore, color: Colors.white, size: 70)),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }

  Widget _buildFeaturedSection(List<MatchModel> matches) {
    // Lấy các trận Sắp diễn ra (NS) và Đang đá (LIVE), loại bỏ trận đã Kết thúc (FT)
    final featured = matches.where((m) => m.status == 'NS' || m.status == 'LIVE').toList();

    if (featured.isEmpty) return const SizedBox();
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: featured.length > 8 ? 8 : featured.length,
        itemBuilder: (context, index) => _buildFeaturedCard(featured[index]),
      ),
    );
  }

  Widget _buildFeaturedCard(MatchModel match) {
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF161F2C), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _leagueBadge(match.leagueName),
              if (match.status == 'LIVE') _liveLabel(match.minuteElapsed),
              if (match.status == 'NS') Text(DateFormat('HH:mm').format(match.startTime), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _teamView(match.homeTeam, match.homeLogo, Colors.blueAccent),
              _scoreView(match),
              _teamView(match.awayTeam, match.awayLogo, Colors.redAccent),
            ],
          ),
          const Spacer(),
          _statsRow(match),
          const SizedBox(height: 12),
          _actionBtn(),
        ],
      ),
    );
  }

  Widget _leagueBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFF3B66F5).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(name.toUpperCase(), style: const TextStyle(color: Color(0xFF3B66F5), fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _liveLabel(int min) {
    return Row(
      children: [
        const Icon(Icons.sensors, color: Colors.redAccent, size: 12),
        const SizedBox(width: 4),
        const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Text('Phút $min\'', style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  Widget _teamView(String name, String? logoUrl, Color color) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          _teamLogo(logoUrl, color, size: 34),
          const SizedBox(height: 8),
          Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _teamLogo(String? url, Color fallbackColor, {double size = 30}) {
    if (url == null || url.isEmpty) {
      return Icon(Icons.shield, color: fallbackColor, size: size);
    }
    
    final cleanUrl = url.trim();
    debugPrint('Logo URL: $cleanUrl');

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: cleanUrl.toLowerCase().contains('.svg')
          ? SvgPicture.network(
              cleanUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Icon(Icons.shield, color: fallbackColor, size: size),
            )
          : Image.network(
              cleanUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.shield, color: fallbackColor, size: size),
            ),
    );
  }

  Widget _scoreView(MatchModel match) {
    bool isNS = match.status == 'NS';
    return Column(
      children: [
        if (isNS)
          Text(DateFormat('HH:mm').format(match.startTime), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))
        else
          Text('${match.homeScore} - ${match.awayScore}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(isNS ? _formatMatchDate(match.startTime) : '⚖ Cân bằng', style: TextStyle(color: isNS ? Colors.white38 : Colors.amber, fontSize: 9)),
      ],
    );
  }

  Widget _statsRow(MatchModel match) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _stat(Icons.bar_chart, '${match.homeShots} ▎ ${match.awayShots}'),
        _stat(Icons.rectangle, '${match.homeYellowCards} ▎ ${match.awayYellowCards}', color: Colors.amber),
        _stat(Icons.rectangle, '${match.homeRedCards} ▎ ${match.awayRedCards}', color: Colors.redAccent),
      ],
    );
  }

  Widget _stat(IconData icon, String val, {Color color = Colors.white24}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(val, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _actionBtn() {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B66F5).withOpacity(0.15), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('✨ Xem Quẻ Dự Đoán', style: TextStyle(color: Color(0xFF7B96F9), fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMatchGroups(List<MatchModel> matches) {
    List<MatchModel> filtered = matches;
    if (_selectedTab == 'Live') filtered = matches.where((m) => m.status == 'LIVE').toList();
    if (_selectedTab == 'Kết thúc') filtered = matches.where((m) => m.status == 'FT').toList();
    if (_selectedTab == 'Sắp diễn ra') filtered = matches.where((m) => m.status == 'NS').toList();

    final live = filtered.where((m) => m.status == 'LIVE').toList();
    final upcoming = filtered.where((m) => m.status == 'NS').toList();
    final finished = filtered.where((m) => m.status == 'FT').toList();

    if (filtered.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Không có trận đấu nào trong quẻ này.', style: TextStyle(color: Colors.white38))));

    return Column(
      children: [
        if (live.isNotEmpty) ...[_buildSectionHeader('▎ĐANG DIỄN RA'), ...live.map((m) => _buildSimpleCard(m))],
        if (upcoming.isNotEmpty) ...[_buildSectionHeader('▎SẮP TỚI'), ...upcoming.map((m) => _buildSimpleCard(m))],
        if (finished.isNotEmpty) ...[_buildSectionHeader('▎KẾT THÚC'), ...finished.map((m) => _buildSimpleCard(m))],
      ],
    );
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDate = DateTime(date.year, date.month, date.day);
    final difference = matchDate.difference(today).inDays;

    if (difference == 0) return 'Hôm nay';
    if (difference == 1) return 'Ngày mai';
    return DateFormat('dd/MM').format(date);
  }

  Widget _buildSimpleCard(MatchModel match) {
    bool isNS = match.status == 'NS';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF161F2C), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              _teamLogo(match.homeLogo, Colors.blueAccent, size: 22),
              const SizedBox(width: 12),
              Text(match.homeTeam, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const Spacer(),
              Text(isNS ? DateFormat('HH:mm').format(match.startTime) : '${match.homeScore}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white10, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _teamLogo(match.awayLogo, Colors.redAccent, size: 22),
              const SizedBox(width: 12),
              Text(match.awayTeam, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const Spacer(),
              Text(isNS ? _formatMatchDate(match.startTime) : '${match.awayScore}', style: TextStyle(color: isNS ? Colors.white38 : Colors.white, fontWeight: FontWeight.bold, fontSize: isNS ? 11 : 16)),
              const SizedBox(width: 26),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          _statsRow(match),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showSeeAll = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          if (showSeeAll) const Text('TẤT CẢ', style: TextStyle(color: Color(0xFF3B66F5), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
