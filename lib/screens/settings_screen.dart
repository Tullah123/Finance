import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../utils/layout.dart';
import 'pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppLockService _lockService = AppLockService();
  bool _isLoading = true;
  bool _lockEnabled = false;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _lockService.loadSettings();
    final biometricsAvailable = await _lockService.isBiometricsAvailable();
    if (!mounted) return;
    setState(() {
      _lockEnabled = settings.isEnabled;
      _biometricsEnabled = settings.biometricsEnabled;
      _hasPin = settings.hasPin;
      _biometricsAvailable = biometricsAvailable;
      _isLoading = false;
    });
  }

  Future<void> _toggleLock(bool value) async {
    if (value && !_hasPin && !_biometricsEnabled) {
      _showMessage('Enable PIN or biometrics first.');
      return;
    }
    await _lockService.setLockEnabled(value);
    if (!mounted) return;
    setState(() => _lockEnabled = value);
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value && !_biometricsAvailable) {
      _showMessage('Biometrics are not available on this device.');
      return;
    }
    await _lockService.setBiometricsEnabled(value);
    if (!mounted) return;
    setState(() {
      _biometricsEnabled = value;
      if (value) {
        _lockEnabled = true;
      } else if (!_hasPin) {
        _lockEnabled = false;
      }
    });
    await _lockService.setLockEnabled(_lockEnabled);
  }

  Future<void> _setPin() async {
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const PinSetupScreen()),
    );
    if (pin == null) return;
    await _lockService.savePin(pin);
    await _lockService.setLockEnabled(true);
    if (!mounted) return;
    setState(() {
      _hasPin = true;
      _lockEnabled = true;
    });
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
          'You will no longer be able to unlock with a PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _lockService.clearPin();
    if (!mounted) return;
    setState(() {
      _hasPin = false;
      if (!_biometricsEnabled) {
        _lockEnabled = false;
      }
    });
    await _lockService.setLockEnabled(_lockEnabled);
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
    final itemGap = AppLayout.itemGap(context);
    final maxWidth = AppLayout.maxContentWidth(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: hPad, vertical: sectionGap),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        Text(
                          'Security',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: itemGap),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('App Lock'),
                                subtitle: const Text(
                                    'Require authentication to open the app'),
                                value: _lockEnabled,
                                onChanged: _toggleLock,
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: const Text('Use biometrics'),
                                subtitle: Text(_biometricsAvailable
                                    ? 'Fingerprint or face unlock'
                                    : 'Not available on this device'),
                                value: _biometricsEnabled,
                                onChanged: _biometricsAvailable
                                    ? _toggleBiometrics
                                    : null,
                              ),
                              const Divider(height: 1),
                              ListTile(
                                title: Text(_hasPin ? 'PIN' : 'Set PIN'),
                                subtitle: Text(_hasPin
                                    ? 'PIN is active'
                                    : 'Add a 4-digit PIN'),
                                trailing: Wrap(
                                  spacing: 6,
                                  children: [
                                    TextButton(
                                      onPressed: _setPin,
                                      child: Text(
                                          _hasPin ? 'Change' : 'Add'),
                                    ),
                                    if (_hasPin)
                                      TextButton(
                                        onPressed: _removePin,
                                        child: const Text('Remove'),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
