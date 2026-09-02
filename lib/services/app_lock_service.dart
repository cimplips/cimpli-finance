import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  AppLockService({
    LocalAuthentication? localAuthentication,
  }) : _localAuthentication =
            localAuthentication ?? LocalAuthentication();

  static const String _enabledKey = 'app_lock_enabled';

  final LocalAuthentication _localAuthentication;

  Future<bool> isEnabled() async {
    final preferences =
        await SharedPreferences.getInstance();

    return preferences.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setBool(
      _enabledKey,
      enabled,
    );
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuthentication.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuthentication.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final supported =
          await _localAuthentication.isDeviceSupported();

      if (!supported) {
        return false;
      }

      return await _localAuthentication.authenticate(
        localizedReason:
            'Gunakan sidik jari atau kunci perangkat untuk membuka Cimpli Finance.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
