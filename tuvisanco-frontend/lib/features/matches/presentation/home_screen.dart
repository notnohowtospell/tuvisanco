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
  bool _isDateSelected = false; // Theo dõi xem user đã chọn ngày cụ thể chưa

  @override
  void initState() {
    super.initState();
    _matchesFuture = _fetchMatches();
  }

  Future<List<MatchModel>> _fetchMatches() async {
    try {
      final String url;
      if (_isDateSelected) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        url = '/matches?date=$dateStr';
      } else {
        url = '/matches'; // Để backend tự chọn ngày gần nhất
      }
      final response = await dioClient.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        final matches = data.map((json) => MatchModel.fromJson(json)).toList();
        // Cập nhật ngày hiển thị theo trận đầu tiên nhận được
        if (matches.isNotEmpty && !_isDateSelected) {
          setState(() {
            _selectedDate = matches.first.startTime.toLocal();
          });
        }
        return matches;
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

    // Dùng BottomSheet thay vì Navigator.push để tránh xung đột go_router trên web
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B0F16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _LeagueFilterSheet(
        matches: matches,
        initiallySelected: _selectedLeagues,
        onConfirm: (selected) {
          setState(() {
            _selectedLeagues = selected;
          });
          Navigator.pop(context);
        },
      ),
    );
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
                _isDateSelected = true;
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
    final proxiedUrl = 'http://127.0.0.1:3005/matches/proxy/image?url=' + Uri.encodeComponent(originalUrl);
    
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

// ── BottomSheet lọc giải đấu (tránh xung đột go_router trên web) ──
class _LeagueFilterSheet extends StatefulWidget {
  final List<MatchModel> matches;
  final List<String> initiallySelected;
  final void Function(List<String>) onConfirm;

  const _LeagueFilterSheet({
    required this.matches,
    required this.initiallySelected,
    required this.onConfirm,
  });

  @override
  State<_LeagueFilterSheet> createState() => _LeagueFilterSheetState();
}

class _LeagueFilterSheetState extends State<_LeagueFilterSheet> {
  late List<String> _selectedLeagues;
  late Map<String, int> _leagueCounts;
  late Map<String, List<String>> _countryGroups;
  late List<String> _sortedCountries;
  late List<String> _allLeagues;

  final Map<String, String> _leagueToCountry = {
    'FIFA World Cup 2026': 'THẾ GIỚI',
    'UEFA Champions League': 'CHÂU ÂU',
    'UEFA Women\'s Champions League': 'CHÂU ÂU',
    'Premier League': 'ANH',
    'Bundesliga': 'ĐỨC',
    'Brasileirão Série A': 'BRAZIL',
    'Brasileirão Série B': 'BRAZIL',
    'Copa América': 'NAM MỸ',
    'Copa do Brasil': 'BRAZIL',
    'CONCACAF Champions Cup': 'CONCACAF',
    'AFC Champions League': 'CHÂU Á',
    'Club World Championship': 'THẾ GIỚI',
    'Africa Cup of Nations': 'CHÂU PHI',
    'Allsvenskan': 'CHÂU ÂU',
  };

  @override
  void initState() {
    super.initState();
    _leagueCounts = {};
    for (var m in widget.matches) {
      _leagueCounts[m.leagueName] = (_leagueCounts[m.leagueName] ?? 0) + 1;
    }
    _allLeagues = _leagueCounts.keys.toList();

    _countryGroups = {};
    for (var league in _allLeagues) {
      final country = _leagueToCountry[league] ?? 'KHÁC';
      (_countryGroups[country] ??= []).add(league);
    }
    // Sắp xếp: THẾ GIỚI lên đầu, rồi theo alphabet
    _sortedCountries = _countryGroups.keys.toList()
      ..sort((a, b) {
        if (a == 'THẾ GIỚI') return -1;
        if (b == 'THẾ GIỚI') return 1;
        if (a == 'CHÂU ÂU') return -1;
        if (b == 'CHÂU ÂU') return 1;
        return a.compareTo(b);
      });

    _selectedLeagues = widget.initiallySelected.isEmpty
        ? List.from(_allLeagues)
        : List.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0B0F16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text('Chọn lọc giải đấu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _sortedCountries.length,
              itemBuilder: (context, index) {
                final country = _sortedCountries[index];
                final leagues = _countryGroups[country]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(country, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ),
                    ...leagues.map((league) {
                      final isChecked = _selectedLeagues.contains(league);
                      final count = _leagueCounts[league] ?? 0;
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isChecked) _selectedLeagues.remove(league);
                          else _selectedLeagues.add(league);
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isChecked ? const Color(0xFF1E2D4A) : const Color(0xFF1E2736),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isChecked ? const Color(0xFF3B66F5).withOpacity(0.5) : Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  color: isChecked ? const Color(0xFF3B66F5) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isChecked ? const Color(0xFF3B66F5) : Colors.white38),
                                ),
                                child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(league, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                                child: Text(count.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          // Bottom bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: const BoxDecoration(
              color: Color(0xFF161F2C),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selectedLeagues = List.from(_allLeagues)),
                    child: const Text('Chọn tất cả', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedLeagues.clear()),
                    child: const Text('Bỏ chọn tất cả', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // Nếu chọn tất cả → trả về rỗng = hiển thị tất cả
                      final result = _selectedLeagues.length == _allLeagues.length
                          ? <String>[]
                          : List<String>.from(_selectedLeagues);
                      widget.onConfirm(result);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(110, 44),
                      backgroundColor: const Color(0xFF3B66F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
