import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/lobbies_provider.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _nameController = TextEditingController();
  final _contributionController = TextEditingController(text: '200');
  
  List<dynamic> _matches = [];
  String? _selectedMatchId;
  int _maxMembers = 10;
  bool _isLoadingMatches = true;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    try {
      final response = await dioClient.get('/matches');
      setState(() {
        _matches = response.data;
        if (_matches.isNotEmpty) {
          _selectedMatchId = _matches[0]['id'];
        }
        _isLoadingMatches = false;
      });
    } catch (e) {
      setState(() => _isLoadingMatches = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi tải danh sách trận đấu.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  void _submit() async {
    final user = ref.read(authProvider);
    final name = _nameController.text.trim();
    final contribText = _contributionController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền tên phòng.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedMatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trận đấu.'), backgroundColor: Colors.red),
      );
      return;
    }

    final int? contribution = int.tryParse(contribText);
    if (contribution == null || contribution < 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số vốn góp tối thiểu là 200 điểm.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (contribution > user.points) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư điểm của bạn không đủ.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final room = await ref.read(lobbiesProvider.notifier).createLobby(
        name: name,
        creatorId: user.userId!,
        matchId: _selectedMatchId!,
        maxMembers: _maxMembers,
        contribution: contribution,
      );

      // Cập nhật lại điểm số của người chơi
      ref.read(authProvider.notifier).loginWithEmail(user.email!, "dummy_password_not_needed"); // Refresh auth
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo phòng cược thành công!'), backgroundColor: Colors.green),
      );

      context.pushReplacement('/rooms/dashboard/${room['code']}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo phòng thất bại: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _openMatchSelectorBottomSheet() {
    // Nhóm trận đấu theo giải đấu
    final Map<String, List<dynamic>> groupedMatches = {};
    for (var match in _matches) {
      final league = match['leagueName'] ?? 'Giải đấu khác';
      if (!groupedMatches.containsKey(league)) {
        groupedMatches[league] = [];
      }
      groupedMatches[league]!.add(match);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusMd),
              topRight: Radius.circular(AppTheme.radiusMd),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'CHỌN TRẬN ĐẤU MỤC TIÊU',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  'Chọn một trận đấu trong các giải đấu đang diễn ra để mở phòng cược.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppTheme.surfaceBorder, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: groupedMatches.entries.map((entry) {
                    final leagueName = entry.key;
                    final matches = entry.value;
                    
                    // Tính số trận Live và Sắp đá
                    final liveCount = matches.where((m) => m['status'] == 'LIVE').length;
                    final upcomingCount = matches.where((m) => m['status'] == 'NS').length;
                    
                    String badgeText = '';
                    if (liveCount > 0) {
                      badgeText += '$liveCount LIVE';
                    }
                    if (upcomingCount > 0) {
                      if (badgeText.isNotEmpty) badgeText += ' | ';
                      badgeText += '$upcomingCount sắp đá';
                    }

                    final String leagueLogo = matches.first['leagueLogo'] ?? 'https://media.api-sports.io/football/leagues/39.png';

                    return Card(
                      color: AppTheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        side: const BorderSide(color: AppTheme.surfaceBorder),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Image.network(
                            leagueLogo,
                            width: 24,
                            height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 24, color: Colors.white),
                          ),
                          title: Text(
                            leagueName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            badgeText.isEmpty ? '${matches.length} trận' : badgeText,
                            style: TextStyle(
                              color: liveCount > 0 ? AppTheme.success : AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: liveCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          children: matches.map((match) {
                            final bool isLive = match['status'] == 'LIVE';
                            final bool isFinished = match['status'] == 'FT';
                            final String statusText = isLive 
                                ? 'LIVE (${match['minuteElapsed']}\')' 
                                : isFinished 
                                    ? 'FINISHED' 
                                    : 'SẮP ĐÁ';
                            
                            final DateTime startTime = DateTime.parse(match['startTime']).toLocal();
                            final String timeStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${startTime.day}/${startTime.month}";

                            return Container(
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 0.8)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                onTap: () {
                                  setState(() {
                                    _selectedMatchId = match['id'];
                                  });
                                  Navigator.pop(context);
                                },
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Image.network(match['homeLogo'] ?? '', width: 16, height: 16, errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 16)),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(match['homeTeam'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Image.network(match['awayLogo'] ?? '', width: 16, height: 16, errorBuilder: (_, __, ___) => const Icon(Icons.shield, size: 16)),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(match['awayTeam'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isLive ? "${match['homeScore']} - ${match['awayScore']}" : timeStr,
                                          style: TextStyle(
                                            color: isLive ? AppTheme.success : Colors.white, 
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            color: isLive ? AppTheme.success : AppTheme.textSecondary,
                                            fontSize: 10,
                                            fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchSelectorField(dynamic selectedMatch) {
    if (_matches.isEmpty) {
      return const Text('Chưa có trận đấu nào trong hệ thống.', style: TextStyle(color: AppTheme.textDisabled));
    }
    
    return InkWell(
      onTap: _openMatchSelectorBottomSheet,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: selectedMatch == null
                  ? const Text('Bấm để chọn trận đấu...', style: TextStyle(color: AppTheme.textDisabled, fontSize: 14))
                  : Row(
                      children: [
                        if (selectedMatch['leagueLogo'] != null)
                          Image.network(selectedMatch['leagueLogo'], width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 20, color: Colors.white))
                        else
                          const Icon(Icons.sports_soccer, size: 20, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${selectedMatch['homeTeam']} vs ${selectedMatch['awayTeam']} (${selectedMatch['leagueName']})",
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final lobbiesState = ref.watch(lobbiesProvider);

    final selectedMatch = _matches.firstWhere(
      (m) => m['id'] == _selectedMatchId,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tạo Phòng Cược'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingMatches
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TÊN PHÒNG CƯỢC',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surface,
                        hintText: "Nhập tên phòng, ví dụ: Ngoại Hạng Anh Final",
                        hintStyle: const TextStyle(color: AppTheme.textDisabled, fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'CHỌN TRẬN ĐẤU MỤC TIÊU',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildMatchSelectorField(selectedMatch),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GIỚI HẠN THÀNH VIÊN',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$_maxMembers người',
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxMembers.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      activeColor: AppTheme.primary,
                      inactiveColor: AppTheme.surfaceElevated,
                      onChanged: (double value) {
                        setState(() => _maxMembers = value.round());
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'SỐ ĐIỂM GÓP VỐN LÀM NHÀ CÁI (POOL)',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contributionController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surface,
                        suffixText: "Điểm",
                        suffixStyle: const TextStyle(color: AppTheme.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Số dư tài khoản: ${user.points} điểm. Tối thiểu 200 điểm.',
                      style: const TextStyle(color: AppTheme.textDisabled, fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    // Preview tỷ lệ sở hữu nhà cái
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quyền sở hữu Nhà Cái',
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Bạn đang sở hữu 100% quỹ nhà cái của phòng cược này.',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: lobbiesState.isLoading ? null : _submit,
                      child: lobbiesState.isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('Tạo Phòng & Nhập Quỹ'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
