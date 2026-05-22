import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AiAvatarWidget extends StatefulWidget {
  final bool isSpeaking;
  final bool isThinking;

  const AiAvatarWidget({
    super.key,
    required this.isSpeaking,
    required this.isThinking,
  });

  @override
  State<AiAvatarWidget> createState() => _AiAvatarWidgetState();
}

class _AiAvatarWidgetState extends State<AiAvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _waveCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..repeat();
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle with pulse
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: widget.isSpeaking ? _pulseAnim.value : 1.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                if (widget.isSpeaking)
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 3,
                      ),
                    ),
                  ),
                // Main avatar
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 20, spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 50),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Status indicator
        if (widget.isThinking)
          _ThinkingDots()
        else if (widget.isSpeaking)
          _SoundWave(controller: _waveCtrl)
        else
          Text(
            'AI Interviewer',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (i) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 200)),
    );
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: c, curve: Curves.easeInOut),
    ))
        .toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Thinking ', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ...List.generate(3, (i) => AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anims[i].value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }
}

class _SoundWave extends StatelessWidget {
  final AnimationController controller;
  const _SoundWave({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Speaking ', style: TextStyle(color: AppColors.success, fontSize: 13)),
        AnimatedBuilder(
          animation: controller,
          builder: (_, __) => Row(
            children: List.generate(5, (i) {
              final h = 4.0 + (12 * (0.5 + 0.5 * (controller.value + i * 0.2) % 1.0));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 3, height: h,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}