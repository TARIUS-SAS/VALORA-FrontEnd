import 'package:flutter/material.dart';
import '../core/constants.dart';

class GradientBg extends StatelessWidget {
  const GradientBg({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Colors.white, Color(0xFFF5FFF8)],
            stops:  [0, 0.5, 1],
          ),
        ),
        child: child,
      );
}

class ValoraLogo extends StatelessWidget {
  const ValoraLogo({super.key});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6B6BE8)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20, offset: const Offset(0, 8),
            )],
          ),
          child: const Center(child: Text('V',
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6B6BE8)],
          ).createShader(b),
          child: const Text('Valora',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        ),
        const SizedBox(height: 4),
        const Text(AppStrings.tagline,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]);
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: child,
      );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('o', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ]);
}
