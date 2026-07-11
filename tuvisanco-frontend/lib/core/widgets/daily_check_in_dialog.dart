import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_check_in_provider.dart';

class DailyCheckInDialog extends ConsumerStatefulWidget {
  final String userId;
  const DailyCheckInDialog({super.key, required this.userId});

  static void show(BuildContext context, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailyCheckInDialog(userId: userId),
    );
  }

  @override
  ConsumerState<DailyCheckInDialog> createState() => _DailyCheckInDialogState();
}

class _DailyCheckInDialogState extends ConsumerState<DailyCheckInDialog> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _burstController;
  final List<Particle> _particles = [];
  bool _isCheckedInSuccess = false;
  int _earnedPoints = 50;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _burstController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Chuẩn bị dữ liệu trạng thái điểm danh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyCheckInProvider.notifier).fetchStatus(widget.userId);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  void _triggerBurst() {
    final random = Random();
    _particles.clear();
    for (int i = 0; i < 40; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 3.0 + random.nextDouble() * 5.0;
      _particles.add(
        Particle(
          x: 0,
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 2.0, // Thêm lực kéo lên trên chút
          color: Colors.primaries[random.nextInt(Colors.primaries.length)].withOpacity(0.8),
          size: 4.0 + random.nextDouble() * 6.0,
        ),
      );
    }
    _burstController.forward(from: 0.0);
  }

  void _handleCheckIn() async {
    try {
      final points = await ref.read(dailyCheckInProvider.notifier).performCheckIn(widget.userId);
      if (points != null) {
        setState(() {
          _earnedPoints = points;
          _isCheckedInSuccess = true;
        });
        _triggerBurst();
        // Sau 2.2 giây tự đóng dialog
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi điểm danh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkInState = ref.watch(dailyCheckInProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Khung chính của Hộp thoại điểm danh
            Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxHeight: 520,
                  maxWidth: 400,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.surface.withOpacity(0.95),
                      const Color(0xFF1E2638).withOpacity(0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: checkInState.isLoading && checkInState.history.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tiêu đề & Icon đóng
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 32),
                              const Text(
                                'QUÀ ĐIỂM DANH',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Điểm danh mỗi ngày để tích lũy điểm đặt cược nhé!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Danh sách 7 ngày điểm danh dạng Hộp quà
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: checkInState.history.map((day) {
                                return _buildDayItem(day);
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Nút bấm hành động
                          if (_isCheckedInSuccess)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Đã nhận +$_earnedPoints Điểm!',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: checkInState.canCheckInToday ? _handleCheckIn : null,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                backgroundColor: checkInState.canCheckInToday
                                    ? Colors.amber.shade400
                                    : AppTheme.surfaceElevated,
                                disabledBackgroundColor: AppTheme.surfaceElevated,
                                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: checkInState.canCheckInToday ? 8 : 0,
                                shadowColor: Colors.amber.shade500.withOpacity(0.4),
                              ),
                              child: Text(
                                checkInState.canCheckInToday ? 'NHẬN ĐIỂM NGAY' : 'HÔM NAY ĐÃ ĐIỂM DANH',
                                style: TextStyle(
                                  color: checkInState.canCheckInToday ? Colors.black : AppTheme.textDisabled,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (checkInState.canCheckInToday)
                            const Text(
                              'Nhấn nút để nhận phần thưởng ngày hôm nay',
                              style: TextStyle(color: AppTheme.textDisabled, fontSize: 11),
                            )
                          else
                            const Text(
                              'Quay lại vào ngày mai để nhận mốc tiếp theo!',
                              style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
              ),
            ),

            // Hiệu ứng pháo hoa giấy bay tung tóe (Confetti Burst)
            if (_isCheckedInSuccess)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burstController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ParticlesPainter(
                        particles: _particles,
                        progress: _burstController.value,
                      ),
                      size: const Size(400, 400),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Vẽ widget cho từng ngày
  Widget _buildDayItem(CheckInDay day) {
    final bool isClaimed = day.status == 'claimed';
    final bool isToday = day.status == 'today';

    return Container(
      width: 62,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.primary.withOpacity(0.1)
            : isClaimed
                ? Colors.green.withOpacity(0.08)
                : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppTheme.primary
              : isClaimed
                  ? Colors.green.withOpacity(0.6)
                  : Colors.white.withOpacity(0.05),
          width: isToday ? 2.0 : 1.0,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: _pulseController.value * 8 + 4,
                  spreadRadius: _pulseController.value * 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            'N. ${day.dayIndex}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday
                  ? AppTheme.primary
                  : isClaimed
                      ? Colors.greenAccent
                      : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          // Icon trạng thái
          if (isClaimed)
            const Icon(Icons.check_circle, color: Colors.green, size: 28)
          else if (isToday)
            ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.15).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.amber, size: 28),
            )
          else
            const Icon(Icons.card_giftcard, color: AppTheme.textDisabled, size: 28),
          const SizedBox(height: 10),
          Text(
            '+${day.points}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isToday
                  ? Colors.white
                  : isClaimed
                      ? Colors.green.shade200
                      : AppTheme.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

// Model Hạt pháo hoa giấy
class Particle {
  double x, y;
  double vx, vy;
  Color color;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.15; // Lực hút trái đất kéo xuống
    vx *= 0.98; // Lực cản không khí
    vy *= 0.98;
  }
}

// Khởi tạo CustomPainter vẽ các hạt bắn pháo hoa
class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Di chuyển canvas về tâm để vẽ bắn ra
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    for (var particle in particles) {
      particle.update();
      paint.color = particle.color.withOpacity((1.0 - progress).clamp(0.0, 1.0));
      
      // Hạt tròn hoặc hạt chữ nhật ngẫu nhiên cho sinh động
      if (particle.size % 2 == 0) {
        canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(particle.x, particle.y),
            width: particle.size * 1.5,
            height: particle.size * 0.8,
          ),
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
