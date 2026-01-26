import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import 'app_lock_screen.dart';
import 'main_screen.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({Key? key}) : super(key: key);

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen>
    with WidgetsBindingObserver {
  final AppLockService _lockService = AppLockService();
  bool _isLocked = false;
  bool _isLoading = true;
  bool _shouldLockOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _shouldLockOnResume = true;
    }
    if (state == AppLifecycleState.resumed && _shouldLockOnResume) {
      _shouldLockOnResume = false;
      _refreshLockState();
    }
  }

  Future<void> _loadLockState() async {
    final settings = await _lockService.loadSettings();
    if (!mounted) return;
    setState(() {
      _isLocked = settings.isEnabled;
      _isLoading = false;
    });
  }

  Future<void> _refreshLockState() async {
    final settings = await _lockService.loadSettings();
    if (!mounted) return;
    setState(() {
      _isLocked = settings.isEnabled;
    });
  }

  void _handleUnlocked() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isLocked) {
      return AppLockScreen(onUnlocked: _handleUnlocked);
    }
    return const MainScreen();
  }
}
