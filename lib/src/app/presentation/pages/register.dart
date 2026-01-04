import 'package:bamboo_app/src/app/presentation/widgets/atom/header_auth.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/modal_snackbar.dart';
import 'package:bamboo_app/src/app/use_cases/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/utils/textfield_validator.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _controllerName = TextEditingController();
  final _controllerEmail = TextEditingController();
  final _controllerPassword = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controllerName.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      final result = await const AuthController().signUp(
        name: _controllerName.text.trim(),
        email: _controllerEmail.text.trim(),
        password: _controllerPassword.text,
      );
      if (mounted) {
        if (result.success) {
          ModalSnackbar(context).showSuccess('Pendaftaran Berhasil! Silakan login.');
        } else {
          ModalSnackbar(context).showError(
            result.errorMessage ?? 'Pendaftaran gagal. Coba lagi.',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                heading: 'Daftar',
                subheading: 'Daftar untuk Melanjutkan',
              ),
              SizedBox(height: 0.03.sh),
              AuthTextField(
                controller: _controllerName,
                validator: TextfieldValidator.validator(TextFieldType.name),
                hintText: 'Nama',
                label: 'Nama',
              ),
              SizedBox(height: 0.02.sh),
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
                    onPressed: _isLoading ? null : _handleRegister,
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
                            'Daftar',
                            style: Theme.of(context).textTheme.bodyLarge!,
                          ),
                  ),
                ],
              ),
              SizedBox(height: 0.025.sh),
              TextButton(
                onPressed: _isLoading ? null : () => router.go('/login'),
                child: const Text('Sudah Punya Akun? Masuk'),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Sedang mendaftar...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
