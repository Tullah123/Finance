import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../services/statement_pdf_service.dart';
import '../services/theme_service.dart';
import '../utils/layout.dart';
import 'pin_setup_screen.dart';

/// Settings screen for appearance, security, and data actions.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppLockService _lockService = AppLockService();
  final DataService _dataService = DataService();
  final StatementPdfService _statementPdfService = StatementPdfService();
  bool _isLoading = true;
  bool _isClearing = false;
  bool _lockEnabled = false;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load current lock settings and biometrics availability.
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

  // Toggle app lock with safety checks.
  Future<void> _toggleLock(bool value) async {
    if (value && !_hasPin && !_biometricsEnabled) {
      _showMessage('Enable PIN or biometrics first.');
      return;
    }
    await _lockService.setLockEnabled(value);
    if (!mounted) return;
    setState(() => _lockEnabled = value);
  }

  // Toggle biometrics and keep lock state consistent.
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

  // Navigate to PIN setup and save.
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

  // Remove PIN after confirmation.
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

  // Double-confirm and erase all stored data.
  Future<void> _confirmEraseData() async {
    final shouldErase = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text(
          'This will delete transactions, budgets, goals, reminders, and statements. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Erase'),
          ),
        ],
      ),
    );

    if (shouldErase != true) return;

    final confirmAgain = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('This cannot be undone'),
        content: const Text(
          'Are you absolutely sure you want to permanently erase all data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Yes, erase all'),
          ),
        ],
      ),
    );

    if (confirmAgain != true) return;
    setState(() => _isClearing = true);
    try {
      final reminders = await _dataService.loadReminders();
      for (final reminder in reminders) {
        await NotificationService.instance.cancelReminderFor(reminder);
      }
      await _dataService.clearAllData();
      await _statementPdfService.deleteAllStatements();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to erase data: $e');
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
                          'Appearance',
                          style: textTheme.titleLarge,
                        ),
                        SizedBox(height: itemGap),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ValueListenableBuilder<AppThemeMode>(
                            valueListenable: ThemeService.modeNotifier,
                            builder: (context, mode, _) {
                              return Column(
                                children: [
                                  RadioListTile<AppThemeMode>(
                                    title: const Text('Light'),
                                    subtitle:
                                        const Text('Default bright theme'),
                                    value: AppThemeMode.light,
                                    groupValue: mode,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      ThemeService.setMode(value);
                                    },
                                  ),
                                  const Divider(height: 1),
                                  RadioListTile<AppThemeMode>(
                                    title: const Text('Dark'),
                                    subtitle: const Text('Dim dark theme'),
                                    value: AppThemeMode.dark,
                                    groupValue: mode,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      ThemeService.setMode(value);
                                    },
                                  ),
                                  const Divider(height: 1),
                                  RadioListTile<AppThemeMode>(
                                    title: const Text('Black'),
                                    subtitle: const Text('Pure black theme'),
                                    value: AppThemeMode.black,
                                    groupValue: mode,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      ThemeService.setMode(value);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        Text(
                          'Security',
                          style: textTheme.titleLarge,
                        ),
                        SizedBox(height: itemGap),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
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
                        SizedBox(height: sectionGap),
                        Text(
                          'Data',
                          style: textTheme.titleLarge,
                        ),
                        SizedBox(height: itemGap),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Erase all data',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Deletes transactions, budgets, goals, reminders, and statements.',
                                style: textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isClearing ? null : _confirmEraseData,
                                  icon: _isClearing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.delete_forever_rounded),
                                  label: Text(
                                    _isClearing
                                        ? 'Erasing...'
                                        : 'Erase Data',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
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

