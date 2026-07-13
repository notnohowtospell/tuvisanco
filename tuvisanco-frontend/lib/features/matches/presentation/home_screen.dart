import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/match_model.dart';
import 'league_filter_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedTab = 'Tất cả';
  DateTime _selectedDate = DateTime.now();
  Future<List<MatchModel>>? _matchesFuture;
  List<String> _selectedLeagues = [];

  @override
  void initState() {
    super.initState();
    _matchesFuture = _fetchMatches();
  }

  Future<List<MatchModel>> _fetchMatches() async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await dioClient.get('/matches?date=$dateStr');
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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async => setState(() { _matchesFuture = _fetchMatches(); }),
        child: Column(
          children: [
            _buildTabs(),
            Expanded(
              child: FutureBuilder<List<MatchModel>>(
                future: _matchesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  }
                  final matches = snapshot.data ?? [];
                  if (matches.isEmpty) {
                    return const Center(child: Text('Không có trận đấu nào.', style: TextStyle(color: Colors.white38)));
                  }
                  return _buildLeagueGroups(matches);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B2342),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Image.asset('assets/images/Logo.png', errorBuilder: (c, e, s) => const Icon(Icons.sports_soccer, color: Colors.blueAccent)),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('BÓNG ĐÁ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(icon: const Icon(Icons.filter_alt_outlined, color: Colors.white), onPressed: _showLeagueFilter),
        IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
        IconButton(icon: const Icon(Icons.star_border, color: Colors.white), onPressed: () {}),
      ],
    );
  }

  void _showLeagueFilter() async {
    final matches = await _matchesFuture;
    if (matches == null || matches.isEmpty) return;

    if (!mounted) return;

    final selected = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => LeagueFilterScreen(
          matches: matches,
          initiallySelected: _selectedLeagues,
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedLeagues = selected;
      });
    }
  }

  Widget _buildTabs() {
    final tabs = ['Tất cả', '● Live', 'Đã kết thúc', 'Sắp diễn ra'];
    return Container(
      color: const Color(0xFF0B0F16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((tab) {
                  bool isSelected = _selectedTab == tab.replaceAll('● ', '');
                  bool isLive = tab.contains('Live');
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab.replaceAll('● ', '')),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B66F5) : const Color(0xFF1E2736),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          if (isLive) ...[
                            const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            tab.replaceAll('● ', ''),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildIconButton(Icons.calendar_month, () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
                _matchesFuture = _fetchMatches();
              });
            }
          }),
          const SizedBox(width: 8),
          _buildIconButton(Icons.menu, () {}),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF1E2736), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }

  Widget _buildLeagueGroups(List<MatchModel> matches) {
    List<MatchModel> filtered = matches;
    if (_selectedTab == 'Live') filtered = matches.where((m) => m.status == 'LIVE').toList();
    if (_selectedTab == 'Đã kết thúc') filtered = matches.where((m) => m.status == 'FT').toList();
    if (_selectedTab == 'Sắp diễn ra') filtered = matches.where((m) => m.status == 'NS').toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Không có trận đấu nào.', style: TextStyle(color: Colors.white38)));
    }

    // Group by league
    Map<String, List<MatchModel>> groups = {};
    for (var m in filtered) {
      if (_selectedLeagues.isNotEmpty && !_selectedLeagues.contains(m.leagueName)) {
        continue;
      }
      if (!groups.containsKey(m.leagueName)) {
        groups[m.leagueName] = [];
      }
      groups[m.leagueName]!.add(m);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: groups.keys.length,
      itemBuilder: (context, index) {
        String league = groups.keys.elementAt(index);
        List<MatchModel> leagueMatches = groups[league]!;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161F2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // League Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B2342),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(league, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    const Icon(Icons.people, color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    const Text('9999+', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              
              // Matches in League
              ...leagueMatches.asMap().entries.map((entry) {
                int idx = entry.key;
                MatchModel m = entry.value;
                return Column(
                  children: [
                    if (idx > 0) const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
                    _buildMatchCard(m),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    bool isNS = match.status == 'NS';
    bool isLive = match.status == 'LIVE';
    
    // Mock half-time score based on full time score
    int h1Home = (match.homeScore / 2).ceil();
    int h1Away = (match.awayScore / 2).ceil();
    
    return InkWell(
      onTap: () => context.push('/match/detail/${match.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Left Column: Time & Status
                SizedBox(
                  width: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_border, color: Colors.white38, size: 20),
                      const SizedBox(height: 8),
                      Text(DateFormat('HH:mm').format(match.startTime), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        isLive ? "${match.minuteElapsed}'" : (isNS ? "Chưa đá" : "Đã kết thúc"),
                        style: TextStyle(color: isLive || !isNS ? Colors.greenAccent : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Middle Column: Teams
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _teamLogo(match.homeLogo, Colors.blueAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(match.homeTeam, style: const TextStyle(color: Colors.white, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _teamLogo(match.awayLogo, Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(match.awayTeam, style: const TextStyle(color: Colors.white, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Right Column: Scores
                SizedBox(
                  width: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(isNS ? '-' : '${match.homeScore}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text(isNS ? '-' : '${match.awayScore}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bottom Stats Row
            Row(
              children: [
                // Home Stats
                _statItem(Icons.flag, '${match.homeShots}', Colors.grey),
                const SizedBox(width: 8),
                _statItem(Icons.rectangle, '${match.homeRedCards}', Colors.red),
                const SizedBox(width: 8),
                _statItem(Icons.rectangle, '${match.homeYellowCards}', Colors.amber),
                
                const Spacer(),
                
                // Middle Icons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF3B66F5), borderRadius: BorderRadius.circular(4)),
                  child: const Text('3D', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF3B66F5), borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.tv, color: Colors.white, size: 10),
                ),
                
                const Spacer(),
                
                // Away Stats
                _statItem(Icons.rectangle, '${match.awayYellowCards}', Colors.amber),
                const SizedBox(width: 8),
                _statItem(Icons.rectangle, '${match.awayRedCards}', Colors.red),
                const SizedBox(width: 8),
                _statItem(Icons.flag, '${match.awayShots}', Colors.grey),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Half Time Score Highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isNS ? 'Chưa có thông tin' : "H1 ($h1Home-$h1Away), 90' (${match.homeScore}-${match.awayScore})",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 10, color: iconColor),
        const SizedBox(width: 2),
        Text(value, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _teamLogo(String? url, Color fallbackColor, {double size = 18}) {
    if (url == null || url.isEmpty) {
      return Icon(Icons.shield, color: fallbackColor, size: size);
    }
    final originalUrl = url.trim();
    final proxiedUrl = 'http://10.0.2.2:3000/matches/proxy/image?url=' + Uri.encodeComponent(originalUrl);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
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
}
