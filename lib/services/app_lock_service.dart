import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockSettings {
  final bool isEnabled;
  final bool biometricsEnabled;
  final bool hasPin;

  const AppLockSettings({
    required this.isEnabled,
    required this.biometricsEnabled,
    required this.hasPin,
  });
}

class AppLockService {
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _biometricsEnabledKey = 'app_lock_biometrics_enabled';
  static const String _pinHashKey = 'app_lock_pin_hash';
  static const String _pinSaltKey = 'app_lock_pin_salt';
  static DateTime? _skipLockUntil;

  final LocalAuthentication _auth = LocalAuthentication();

  static void skipNextLock({Duration duration = const Duration(seconds: 6)}) {
    _skipLockUntil = DateTime.now().add(duration);
  }

  static bool shouldSkipLock() {
    final until = _skipLockUntil;
    if (until == null) {
      return false;
    }
    if (DateTime.now().isBefore(until)) {
      return true;
    }
    _skipLockUntil = null;
    return false;
  }

  Future<AppLockSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_lockEnabledKey) ?? false;
    final biometricsEnabled = prefs.getBool(_biometricsEnabledKey) ?? false;
    final hasPin = prefs.getString(_pinHashKey) != null;
    return AppLockSettings(
      isEnabled: isEnabled,
      biometricsEnabled: biometricsEnabled,
      hasPin: hasPin,
    );
  }

  Future<void> setLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, value);
  }

  Future<void> setBiometricsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, value);
  }

  Future<bool> isBiometricsAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final supported = await _auth.isDeviceSupported();
    return canCheck && supported;
  }

  Future<bool> authenticateWithBiometrics() async {
    final canCheck = await isBiometricsAvailable();
    if (!canCheck) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock your finance data',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await prefs.setString(_pinSaltKey, salt);
    await prefs.setString(_pinHashKey, hash);
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinSaltKey);
    await prefs.remove(_pinHashKey);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_pinSaltKey);
    final hash = prefs.getString(_pinHashKey);
    if (salt == null || hash == null) {
      return false;
    }
    return _hashPin(pin, salt) == hash;
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin');
    return sha256.convert(bytes).toString();
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
