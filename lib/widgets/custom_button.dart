import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

import 'package:flutter/services.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.color,
  });

  void _handleTap() {
    if (onTap != null && !isLoading) {
      HapticFeedback.lightImpact();
      onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 56,
      child: isOutlined
          ? OutlinedButton.icon(
        onPressed: isLoading ? null : _handleTap,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: isLoading
            ? const SizedBox(
          height: 20, width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color ?? AppColors.primary, width: 2),
          foregroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      )
          : DecoratedBox(
        decoration: BoxDecoration(
          gradient: color != null
              ? LinearGradient(colors: [color!, color!.withOpacity(0.7)])
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (color ?? AppColors.primary).withOpacity(0.4),
              blurRadius: 12, offset: const Offset(0, 6),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : _handleTap,
          icon: icon != null ? Icon(icon, color: Colors.white) : const SizedBox.shrink(),
          label: isLoading
              ? const SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : Text(text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}