import 'package:bamboo_app/src/app/blocs/user_logged_state.dart';
import 'package:bamboo_app/src/app/routes/routes.dart';
import 'package:bamboo_app/src/core/network/api_exception.dart';
import 'package:bamboo_app/src/domain/entities/e_user.dart';
import 'package:bamboo_app/src/domain/service/s_user.dart';
import 'package:bamboo_app/utils/default_user.dart';

class AuthResult {
  const AuthResult({
    required this.success,
    this.errorMessage,
    this.fieldErrors,
    this.user,
  });

  final bool success;
  final String? errorMessage;
  final Map<String, String>? fieldErrors;
  final EntitiesUser? user;
}

typedef RegisterResult = AuthResult;
typedef LoginResult = AuthResult;

class AuthController {
  AuthController({UserLoggedStateBloc? userBloc}) : _userBloc = userBloc;

  final UserLoggedStateBloc? _userBloc;
  final ServiceUser _serviceUser = ServiceUser();

  Future<LoginResult> signIn(String email, String password) async {
    try {
      final user = await _serviceUser.signIn(email, password);

      // Update user state
      defaultUser = user;
      _userBloc?.add(UserLoggedInEvent(user: user));

      // Navigate to dashboard
      router.go('/dashboard');

      return LoginResult(success: true, user: user);
    } on ValidationException catch (e) {
      return LoginResult(
        success: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
    } on UnauthorizedException catch (_) {
      return const LoginResult(
        success: false,
        errorMessage: 'Email atau password salah',
      );
    } on NetworkException catch (_) {
      return const LoginResult(
        success: false,
        errorMessage: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on ApiException catch (e) {
      return LoginResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return LoginResult(
        success: false,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  Future<RegisterResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _serviceUser.signUp(
        name: name,
        email: email,
        password: password,
      );
      router.go('/login');
      return const RegisterResult(success: true);
    } on ValidationException catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: e.message,
        fieldErrors: e.fieldErrors,
      );
    } on ConflictException catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: 'Email sudah terdaftar',
        fieldErrors: {'email': e.message},
      );
    } on NetworkException catch (_) {
      return const RegisterResult(
        success: false,
        errorMessage: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on ApiException catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: e.message,
      );
    } catch (e) {
      return RegisterResult(
        success: false,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  Future<bool> restoreSession() async {
    try {
      final user = await _serviceUser.restoreSession();
      if (user != null) {
        defaultUser = user;
        _userBloc?.add(UserLoggedInEvent(user: user));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _serviceUser.logout();
    _userBloc?.add(UserLoggedOutEvent());
    router.go('/login');
  }
}
