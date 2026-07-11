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

      // Cập nhật lại số điểm của người dùng trên Client
      // (Nhân tiện đồng bộ lại AuthNotifier để khớp điểm số)
      ref.read(authProvider.notifier).loginWithEmail(user.email!, "dummy_password_not_needed"); // Refresh auth
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo phòng cược thành công!'), backgroundColor: Colors.green),
      );

      // Điều hướng về màn Dashboard quản lý của Chủ phòng vừa tạo
      context.pushReplacement('/rooms/dashboard/${room['code']}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo phòng thất bại: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final lobbiesState = ref.watch(lobbiesProvider);

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
                    _matches.isEmpty
                        ? const Text('Chưa có trận đấu nào trong hệ thống.', style: TextStyle(color: AppTheme.textDisabled))
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedMatchId,
                                dropdownColor: AppTheme.surface,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                items: _matches.map((match) {
                                  return DropdownMenuItem<String>(
                                    value: match['id'],
                                    child: Text(
                                      "${match['homeTeam']} vs ${match['awayTeam']} (${match['leagueName']})",
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedMatchId = value);
                                },
                              ),
                            ),
                          ),
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
