import 'package:bamboo_app/src/app/blocs/user_logged_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/retry_button.dart';
import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/src/app/use_cases/auth_controller.dart';
import 'package:bamboo_app/src/app/use_cases/permission_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  String _status = 'Sedang Meminta Izin...';
  bool _hasError = false;
  final _storage = const FlutterSecureStorage();
  static const _onboardingKey = 'onboarding_completed';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void permissionCallback(String permission) {
    setState(() => _status = permission);
  }

  Future<void> _initialize() async {
    setState(() => _hasError = false);

    // Request permissions first
    bool pLocation = await PermissionController(callback: permissionCallback)
        .reqLocationPermission();
    bool pMedia = await PermissionController(callback: permissionCallback)
        .reqMediaPermission();

    if (pLocation && pMedia) {
      // Try to restore session
      setState(() => _status = 'Memuat sesi...');
      await _restoreSessionAndNavigate();
    } else {
      setState(() => _hasError = true);
    }
  }

  Future<bool> _hasCompletedOnboarding() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  Future<void> _restoreSessionAndNavigate() async {
    // Check if onboarding has been completed
    final onboardingCompleted = await _hasCompletedOnboarding();
    if (!onboardingCompleted) {
      router.go('/onboarding');
      return;
    }

    if (!mounted) return;

    final userBloc = context.read<UserLoggedStateBloc>();
    final authController = AuthController(userBloc: userBloc);

    final hasValidSession = await authController.restoreSession();

    if (hasValidSession) {
      router.go('/dashboard');
    } else {
      router.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.3, -0.8),
            end: Alignment(0.5, 0.8),
            colors: [
              Color(0xCCFFBF00), // rgba(255, 191, 0, 0.8)
              Color(0xE662A148), // rgba(98, 161, 72, 0.9)
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo with decoration
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Decoration behind logo
                    Positioned(
                      bottom: 0,
                      child: Image.asset(
                        'assets/images/splash_decoration.png',
                        width: 140,
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Main logo
                    Positioned(
                      top: 0,
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        width: 140,
                        height: 135,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Bamboo Mapper',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'Lacak Bambu, Di Mana Saja',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(flex: 2),
              // Status indicator at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  children: [
                    if (!_hasError) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      _status,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_hasError) ...[
                      const SizedBox(height: 16),
                      RetryButton(onTap: () async => await _initialize()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
