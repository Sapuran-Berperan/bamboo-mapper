import 'package:bamboo_app/src/app/blocs/user_logged_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/retry_button.dart';
import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/src/app/use_cases/auth_controller.dart';
import 'package:bamboo_app/src/app/use_cases/permission_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  String _status = 'Sedang Meminta Izin...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void permissionCallback(String permission) {
    setState(() => _status = permission);
  }

  Future<void> _initialize() async {
    // Request permissions first
    bool pLocation = await PermissionController(callback: permissionCallback)
        .reqLocationPermission();
    bool pMedia = await PermissionController(callback: permissionCallback)
        .reqMediaPermission();

    if (pLocation && pMedia) {
      // Try to restore session
      setState(() => _status = 'Memuat sesi...');
      await _restoreSessionAndNavigate();
    }
  }

  Future<void> _restoreSessionAndNavigate() async {
    final userBloc = context.read<UserLoggedStateBloc>();
    final authController = AuthController(userBloc: userBloc);

    final hasValidSession = await authController.restoreSession();

    if (hasValidSession) {
      router.go('/dashboard');
    } else {
      router.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _status,
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
            textAlign: TextAlign.center,
          ),
          const Padding(padding: EdgeInsets.only(top: 20)),
          RetryButton(onTap: () async => await _initialize()),
        ],
      ),
    );
  }
}
