import 'dart:convert'; // Encoding text -> bytes (needed for hashing).
import 'dart:math'; // Secure random number generation.

import 'package:crypto/crypto.dart'; // SHA-256 hashing algorithm (for PIN).
import 'package:local_auth/local_auth.dart'; // Fingerprint/face ID biometrics.
import 'package:shared_preferences/shared_preferences.dart'; // Local key-value storage (saves settings on device).

/// Value object describing current app lock settings.
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

/// Handles PIN and biometrics lock settings + verification.
class AppLockService {
  // Preference keys for persisted lock state (leading underscore = private).
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _biometricsEnabledKey = 'app_lock_biometrics_enabled';
  static const String _pinHashKey = 'app_lock_pin_hash';
  static const String _pinSaltKey = 'app_lock_pin_salt';
  static DateTime? _skipLockUntil; // Used to avoid immediate relock loops.

  // Handles fingerprint / face ID prompts.
  final LocalAuthentication _auth = LocalAuthentication();

  // Temporarily skip the lock check after an unlock.
  static void skipNextLock({Duration duration = const Duration(seconds: 6)}) {
    _skipLockUntil = DateTime.now().add(duration);
  }

  // True means "do not lock" for a short window.
  static bool shouldSkipLock() {
    final until = _skipLockUntil;
    if (until == null) {
      return false; // No skip active -> lock normally.
    }
    if (DateTime.now().isBefore(until)) {
      return true; // Still within skip window -> skip lock.
    }
    _skipLockUntil = null; // Skip expired.
    return false; // Lock allowed.
  }

  // Load current lock settings from local storage.
  Future<AppLockSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_lockEnabledKey) ?? false; // Default false.
    final biometricsEnabled = prefs.getBool(_biometricsEnabledKey) ?? false;
    final hasPin = prefs.getString(_pinHashKey) != null; // PIN hash exists.
    return AppLockSettings(
      isEnabled: isEnabled,
      biometricsEnabled: biometricsEnabled,
      hasPin: hasPin,
    );
  }

  // Persist app lock enabled flag.
  Future<void> setLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockEnabledKey, value);
  }

  // Persist biometrics enabled flag.
  Future<void> setBiometricsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, value);
  }

  // Check if device supports biometrics.
  Future<bool> isBiometricsAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final supported = await _auth.isDeviceSupported();
    return canCheck && supported;
  }

  // Trigger system biometrics prompt (true on success).
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
      // Any error should fail safely.
      return false;
    }
  }

  // Store a hashed PIN with salt.
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await prefs.setString(_pinSaltKey, salt);
    await prefs.setString(_pinHashKey, hash);
  }

  // Remove stored PIN.
  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinSaltKey);
    await prefs.remove(_pinHashKey);
  }

  // Compare entered PIN with stored hash.
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_pinSaltKey);
    final hash = prefs.getString(_pinHashKey);
    if (salt == null || hash == null) {
      return false; // No PIN set.
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
