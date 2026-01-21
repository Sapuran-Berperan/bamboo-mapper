import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bamboo_app/src/app/blocs/user_logged_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/modal_snackbar.dart';
import 'package:bamboo_app/src/app/use_cases/auth_controller.dart';
import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/utils/textfield_validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controllerEmail = TextEditingController();
  final _controllerPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String email, String password) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userBloc = context.read<UserLoggedStateBloc>();
      final result = await AuthController(userBloc: userBloc).signIn(
        email.trim(),
        password,
      );
      if (mounted) {
        if (result.success) {
          ModalSnackbar(context).showSuccess('Login Berhasil');
        } else {
          ModalSnackbar(context).showError(
            result.errorMessage ?? 'Email atau password salah',
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
    return BlocBuilder<UserLoggedStateBloc, UserLoggedState>(
      builder: (context, state) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.3, -0.8),
                end: Alignment(0.5, 0.8),
                colors: [
                  Color(0xCCFFBF00), // Golden yellow
                  Color(0xE662A148), // Green
                ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative ellipses
                Positioned(
                  top: -100,
                  left: -150,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -200,
                  right: -200,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // Back button
                          GestureDetector(
                            onTap: () => router.go('/welcome'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF1A1C1E),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Logo with circular background
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFFF4D6), // Cream/yellow background
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/images/splash_logo.png',
                                        width: 70,
                                        height: 67,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Title
                                  const Text(
                                    'Selamat Datang!',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                      letterSpacing: -0.64,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Subtitle
                                  const Text(
                                    'Masukkan email dan kata sandi Anda untuk masuk',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6C7278),
                                      letterSpacing: -0.12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  // Email field
                                  _buildTextField(
                                    controller: _controllerEmail,
                                    hintText: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: TextfieldValidator.validator(TextFieldType.email),
                                  ),
                                  const SizedBox(height: 6),
                                  // Password field
                                  _buildTextField(
                                    controller: _controllerPassword,
                                    hintText: 'Password',
                                    isPassword: true,
                                    obscureText: _obscurePassword,
                                    onToggleVisibility: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                    validator: TextfieldValidator.validator(TextFieldType.password),
                                  ),
                                  const SizedBox(height: 16),
                                  // Remember me & Forgot password
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Remember me
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _rememberMe = !_rememberMe);
                                        },
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 19,
                                              height: 19,
                                              decoration: BoxDecoration(
                                                color: _rememberMe ? const Color(0xFF62A148) : Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: _rememberMe
                                                      ? const Color(0xFF62A148)
                                                      : const Color(0xFF6C7278),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: _rememberMe
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 14,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 5),
                                            const Text(
                                              'Remember me',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF6C7278),
                                                letterSpacing: -0.12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Forgot password
                                      GestureDetector(
                                        onTap: _isLoading ? null : () {
                                          // TODO: Implement forgot password
                                        },
                                        child: const Text(
                                          'Forgot Password ?',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF62A148),
                                            letterSpacing: -0.12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Login button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _handleLogin(
                                                _controllerEmail.text,
                                                _controllerPassword.text,
                                              ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF62A148),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: const Color(0xFF62A148).withValues(alpha: 0.6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Masuk',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.14,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Register link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Tidak Punya Akun?',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6C7278),
                                          letterSpacing: -0.12,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: _isLoading ? null : () => router.go('/register'),
                                        child: const Text(
                                          'Daftar',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF62A148),
                                            letterSpacing: -0.12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Loading overlay
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Sedang masuk...',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1C1E),
        letterSpacing: -0.14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFACB5BB),
          letterSpacing: -0.14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFEDF1F3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFEDF1F3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF62A148),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFFACB5BB),
                  size: 20,
                ),
              )
            : null,
      ),
      validator: validator,
    );
  }
}
