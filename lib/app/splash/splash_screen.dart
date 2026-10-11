import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qanat/app/router/app_router.dart';
import 'package:qanat/core/design_system/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    _timer = Timer(const Duration(milliseconds: 1450), () {
      if (mounted) context.go(AppRoutes.explore);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -110,
              right: -90,
              child: _Circle(
                size: 280,
                color: AppColors.onPrimary.withValues(alpha: .06),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -130,
              child: _Circle(
                size: 330,
                color: AppColors.accent.withValues(alpha: .12),
              ),
            ),
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 700),
                opacity: _visible ? 1 : 0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutBack,
                  scale: _visible ? 1 : .88,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: AppColors.onPrimary,
                          borderRadius: AppRadii.hero,
                          boxShadow: AppShadows.onDark,
                        ),
                        child: const Icon(
                          Icons.flight_rounded,
                          size: 42,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Qanat',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: AppColors.onPrimary,
                              letterSpacing: -1.2,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Әр сапарға ақылды таңдау',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppColors.onPrimaryMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.page,
              right: AppSpacing.page,
              bottom: AppSpacing.xxl,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 900),
                opacity: _visible ? 1 : 0,
                child: const LinearProgressIndicator(
                  minHeight: 2,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  color: AppColors.onPrimary,
                  backgroundColor: AppColors.onPrimaryFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
