import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../utils/layout.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final bool allowCancel;

  const AppLockScreen({
    Key? key,
    required this.onUnlocked,
    this.allowCancel = false,
  }) : super(key: key);

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final AppLockService _lockService = AppLockService();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = true;
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  bool _hasPin = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final settings = await _lockService.loadSettings();
    final biometricsAvailable = await _lockService.isBiometricsAvailable();
    if (!mounted) return;
    setState(() {
      _biometricsAvailable = biometricsAvailable;
      _biometricsEnabled = settings.biometricsEnabled;
      _hasPin = settings.hasPin;
      _isLoading = false;
    });
    if (_biometricsEnabled && _biometricsAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateWithBiometrics();
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    final success = await _lockService.authenticateWithBiometrics();
    if (!mounted) return;
    setState(() => _isAuthenticating = false);
    if (success) {
      AppLockService.skipNextLock();
      widget.onUnlocked();
    } else {
      _showMessage('Biometric authentication failed.');
    }
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      _showMessage('Enter your 4-digit PIN.');
      return;
    }
    final isValid = await _lockService.verifyPin(pin);
    if (!mounted) return;
    if (isValid) {
      AppLockService.skipNextLock();
      widget.onUnlocked();
    } else {
      _showMessage('Incorrect PIN.');
      _pinController.clear();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.horizontalPadding(context);
    final sectionGap = AppLayout.sectionGap(context);
    final maxWidth = AppLayout.maxContentWidth(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && widget.allowCancel) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: sectionGap,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B998B).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 48,
                        color: Color(0xFF1B998B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Unlock your account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use biometrics or your PIN to continue.',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: sectionGap),
                    if (_hasPin)
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: 'PIN',
                          hintText: 'Enter 4-digit PIN',
                          counterText: '',
                        ),
                        onSubmitted: (_) => _unlockWithPin(),
                      ),
                    if (_hasPin) const SizedBox(height: 12),
                    if (_hasPin)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _unlockWithPin,
                          child: const Text('Unlock'),
                        ),
                      ),
                    if (_biometricsEnabled && _biometricsAvailable) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isAuthenticating
                              ? null
                              : _authenticateWithBiometrics,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: Text(
                            _isAuthenticating
                                ? 'Checking...'
                                : 'Use fingerprint / face',
                          ),
                        ),
                      ),
                    ],
                    if (!_hasPin &&
                        !(_biometricsEnabled && _biometricsAvailable)) ...[
                      const SizedBox(height: 12),
                      Text(
                        'No unlock method is configured.',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
