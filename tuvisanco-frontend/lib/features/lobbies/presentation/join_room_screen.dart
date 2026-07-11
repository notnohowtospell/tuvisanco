import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../data/lobbies_provider.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Tạo hiệu ứng lắc ngang khi có lỗi
    _shakeAnimation = Tween<double>(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        }
      });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(int index, String value) {
    if (value.isNotEmpty) {
      _controllers[index].text = value.toUpperCase();
      if (index < 5) {
        _focusNodes[index].unfocus();
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
        _submit();
      }
    }
  }

  void _submit() async {
    final user = ref.read(authProvider);
    String code = _controllers.map((c) => c.text).join();
    
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 ký tự mã mời.'), backgroundColor: Colors.red),
      );
      _triggerShake();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final room = await ref.read(lobbiesProvider.notifier).joinLobby(user.userId!, code);
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gia nhập phòng cược thành công!'), backgroundColor: Colors.green),
      );
      
      // Chuyển sang màn hình chi tiết phòng cược của thành viên
      context.pushReplacement('/rooms/detail/${room['code']}');
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy phòng: ${e.toString()}'), backgroundColor: Colors.red),
      );
      _triggerShake();
    }
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
    // Xóa sạch các ô nhập
    for (var controller in _controllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(_focusNodes[0]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gia Nhập Phòng'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, size: 70, color: AppTheme.primary),
                const SizedBox(height: 24),
                const Text(
                  'NHẬP MÃ PIN MỜI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập 6 ký tự mã mời từ chủ phòng để gia nhập cuộc vui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 32),

                // PIN Code Entry Grid (Với hiệu ứng rung lắc)
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    double offset = sin(_shakeAnimation.value * pi * 2) * 8;
                    return Transform.translate(
                      offset: Offset(offset, 0.0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          decoration: InputDecoration(
                            counterText: "",
                            filled: true,
                            fillColor: AppTheme.surface,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                            ),
                          ),
                          onChanged: (value) => _onKeyPress(index, value),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Xác nhận vào phòng'),
                ),
                const SizedBox(height: 20),
                
                TextButton.icon(
                  onPressed: () {
                    // TODO: Tích hợp quét mã QR
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng quét QR đang được phát triển.')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondary, size: 20),
                  label: const Text(
                    'Quét mã QR Phòng cược',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
