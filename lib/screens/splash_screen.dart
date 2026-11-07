import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/history_provider.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  final StorageService storageService;

  const SplashScreen({super.key, required this.storageService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Memeriksa sesi login & token...';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _checkAuthTokenAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthTokenAndNavigate() async {
    // Beri jeda sejenak agar logo terlihat anggun dan token terverifikasi
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final session = SupabaseService.currentSession;
    final isGuest = widget.storageService.isGuestMode();

    if (session != null) {
      // Token/Sesi aktif ditemukan!
      setState(() {
        _statusMessage = 'Sesi aktif ditemukan. Menghubungkan...';
      });

      // Sinkronkan data profil & riwayat
      if (mounted) {
        final profile = Provider.of<ProfileProvider>(context, listen: false);
        final history = Provider.of<HistoryProvider>(context, listen: false);
        profile.syncWithSupabase();
        history.syncWithSupabase();
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      _navigateToHome();
    } else if (isGuest) {
      // Pengguna sebelumnya memilih mode tamu
      setState(() {
        _statusMessage = 'Memuat mode tamu...';
      });
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      _navigateToHome();
    } else {
      // Token tidak ada & belum login -> Arahkan ke Auth Page
      setState(() {
        _statusMessage = 'Menuju halaman login...';
      });
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => AuthScreen(storageService: widget.storageService),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) =>
            MainNavigationScaffold(storageService: widget.storageService),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/branding/icon_foreground.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield_outlined,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'AllerScan',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Deteksi Alergen Pangan Cerdas & Aman',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),

                // Progress Indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Status Text
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.outline,
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

