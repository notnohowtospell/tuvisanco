import 'package:flutter/material.dart';
import '../data/match_model.dart';

class LeagueFilterScreen extends StatefulWidget {
  final List<MatchModel> matches;
  final List<String> initiallySelected;

  const LeagueFilterScreen({
    super.key,
    required this.matches,
    required this.initiallySelected,
  });

  @override
  State<LeagueFilterScreen> createState() => _LeagueFilterScreenState();
}

class _LeagueFilterScreenState extends State<LeagueFilterScreen> {
  late List<String> _selectedLeagues;
  late List<String> _allLeagues;
  late Map<String, int> _leagueCounts;
  late Map<String, List<String>> _countryGroups;
  late List<String> _sortedCountries;

  // Map league to country
  final Map<String, String> _leagueToCountry = {
    'FIFA World Cup': 'THẾ GIỚI',
    'UEFA Champions League': 'CHÂU ÂU',
    'Premier League': 'ANH',
    'Championship': 'ANH',
    'Primera Division': 'TÂY BAN NHA',
    'Serie A': 'Ý',
    'Bundesliga': 'ĐỨC',
    'DFB Pokal': 'ĐỨC',
    'Ligue 1': 'PHÁP',
    'Eredivisie': 'HÀ LAN',
    'Primeira Liga': 'BỒ ĐÀO NHA',
    'Campeonato Brasileiro Série A': 'BRAZIL',
    'Copa Libertadores': 'NAM MỸ',
  };

  @override
  void initState() {
    super.initState();

    // Pre-compute once
    _leagueCounts = {};
    for (var m in widget.matches) {
      _leagueCounts[m.leagueName] = (_leagueCounts[m.leagueName] ?? 0) + 1;
    }
    _allLeagues = _leagueCounts.keys.toList();

    // Group by country
    _countryGroups = {};
    for (var league in _allLeagues) {
      final country = _leagueToCountry[league] ?? 'KHÁC';
      (_countryGroups[country] ??= []).add(league);
    }
    _sortedCountries = _countryGroups.keys.toList()..sort();

    // Init selection - if empty means "all selected"
    if (widget.initiallySelected.isEmpty) {
      _selectedLeagues = List.from(_allLeagues);
    } else {
      _selectedLeagues = List.from(widget.initiallySelected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2342),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn lọc giải đấu',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _sortedCountries.length,
              itemBuilder: (context, index) {
                final country = _sortedCountries[index];
                final leagues = _countryGroups[country]!;
                return _buildCountryGroup(country, leagues);
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCountryGroup(String country, List<String> leagues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            country,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...leagues.map((league) => _buildLeagueRow(league)),
      ],
    );
  }

  Widget _buildLeagueRow(String league) {
    final isChecked = _selectedLeagues.contains(league);
    final count = _leagueCounts[league] ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isChecked) {
            _selectedLeagues.remove(league);
          } else {
            _selectedLeagues.add(league);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2736),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF3B66F5) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isChecked ? const Color(0xFF3B66F5) : Colors.white38,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                league,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
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
                // Empty list = show all
                if (_selectedLeagues.length == _allLeagues.length) {
                  Navigator.pop(context, <String>[]);
                } else {
                  Navigator.pop(context, List.from(_selectedLeagues));
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(110, 44),
                backgroundColor: const Color(0xFF3B66F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 0,
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
