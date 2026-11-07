import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/profile_provider.dart';
import 'providers/history_provider.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/input_method_screen.dart';
import 'screens/history_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();

  // Inisialisasi koneksi Supabase
  await SupabaseService.init(storageService: storageService);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider(create: (_) => ProfileProvider(storageService)),
        ChangeNotifierProvider(create: (_) => HistoryProvider(storageService)),
      ],
      child: AllerScanApp(storageService: storageService),
    ),
  );
}

class AllerScanApp extends StatelessWidget {
  final StorageService storageService;

  const AllerScanApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AllerScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(storageService: storageService),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  final StorageService storageService;

  const MainNavigationScaffold({super.key, required this.storageService});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;
  bool _isOnboarding = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // First run checks if user completed profile onboarding
    if (!widget.storageService.hasCompletedOnboarding()) {
      _isOnboarding = true;
      _currentIndex = 2; // Open Profile screen on step 1/3
    }

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final isGuest = widget.storageService.isGuestMode();
      if (session == null && !isGuest && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AuthScreen(storageService: widget.storageService),
          ),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _onCompleteOnboarding() {
    widget.storageService.setCompletedOnboarding(true);
    setState(() {
      _isOnboarding = false;
      _currentIndex = 0; // Switch to Scan screen
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      InputMethodScreen(
        onManageProfile: () {
          setState(() => _currentIndex = 2);
        },
      ),
      const HistoryScreen(),
      ProfileScreen(
        isOnboarding: _isOnboarding,
        onSaved: () {
          if (_isOnboarding) {
            _onCompleteOnboarding();
          }
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _isOnboarding
          ? null
          : AppBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
    );
  }
}
