import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CountdownTimerWidget extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeUp;

  const CountdownTimerWidget({
    super.key,
    required this.seconds,
    required this.onTimeUp,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        widget.onTimeUp();
      } else {
        setState(() => _remaining--);
        if (_remaining <= 10) _shakeCtrl.repeat(reverse: true);
      }
    });
  }

  Color get _timerColor {
    if (_remaining <= 10) return AppColors.timerDanger;
    if (_remaining <= 30) return AppColors.timerWarning;
    return AppColors.success;
  }

  String get _timeStr {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (_, child) => Transform.translate(
        offset: _remaining <= 10
            ? Offset(2 * (_shakeCtrl.value - 0.5), 0)
            : Offset.zero,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _timerColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _timerColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, color: _timerColor, size: 16),
            const SizedBox(width: 6),
            Text(
              _timeStr,
              style: TextStyle(
                color: _timerColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}