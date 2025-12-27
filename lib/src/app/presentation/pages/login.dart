import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bamboo_app/src/app/blocs/user_logged_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/header_auth.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/modal_snackbar.dart';
import 'package:bamboo_app/src/app/use_cases/auth_controller.dart';
import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/utils/textfield_validator.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controllerEmail = TextEditingController();
  final _controllerPassword = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      final res = await const AuthController().signIn(email, password);
      if (mounted) {
        res
            ? ModalSnackbar(context).showSuccess('Login Berhasil')
            : ModalSnackbar(context).showError('Email atau password salah');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserLoggedStateBloc, UserLoggedState>(
      builder: (context, state) {
        return Stack(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 0.05.sw, vertical: 0.05.sh),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const HeaderAuth(
                    heading: 'Masuk',
                    subheading: 'Masuk untuk Melanjutkan',
                  ),
                  SizedBox(height: 0.03.sh),
                  AuthTextField(
                    controller: _controllerEmail,
                    validator: TextfieldValidator.validator(TextFieldType.email),
                    hintText: 'Email',
                    label: 'Email',
                  ),
                  SizedBox(height: 0.02.sh),
                  AuthTextField(
                    controller: _controllerPassword,
                    validator: TextfieldValidator.validator(TextFieldType.password),
                    hintText: 'Password',
                    label: 'Password',
                  ),
                  SizedBox(height: 0.02.sh),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _handleLogin(
                                  _controllerEmail.text,
                                  _controllerPassword.text,
                                ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                'Login',
                                style: Theme.of(context).textTheme.bodyLarge!,
                              ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : () {},
                        child: const Text('Lupa Password?'),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.025.sh),
                  TextButton(
                    onPressed: _isLoading ? null : () => router.go('/register'),
                    child: const Text('Belum Punya Akun? Buat Akun'),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => _handleLogin('alan@gmail.com', 'alanalan'),
                    child: const Text('Bypass Login'),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Sedang masuk...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
