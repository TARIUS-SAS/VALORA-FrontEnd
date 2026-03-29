import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isAccent  = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final gradient = isAccent
        ? const LinearGradient(colors: [AppColors.accent, Color(0xFF36D6A0)])
        : const LinearGradient(colors: [AppColors.primary, Color(0xFF6B6BE8)]);
    final shadow = isAccent
        ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
        : [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))];
    final disabled = onPressed == null || isLoading;

    return GestureDetector(
      onTap: disabled ? null : onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: disabled
              ? const LinearGradient(colors: [AppColors.textHint, AppColors.textHint])
              : gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: disabled ? [] : shadow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
              : Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
