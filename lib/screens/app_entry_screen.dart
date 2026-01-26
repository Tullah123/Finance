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
  bool _isLoading = true;
  bool _lockEnabled = false;
  bool _lockRouteVisible = false;
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
      if (AppLockService.shouldSkipLock()) {
        return;
      }
      _refreshLockState();
    }
  }

  Future<void> _loadLockState() async {
    final settings = await _lockService.loadSettings();
    if (!mounted) return;
    setState(() {
      _lockEnabled = settings.isEnabled;
      _isLoading = false;
    });
    if (_lockEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _presentLockScreen();
      });
    }
  }

  Future<void> _refreshLockState() async {
    final settings = await _lockService.loadSettings();
    if (!mounted) return;
    setState(() {
      _lockEnabled = settings.isEnabled;
    });
    if (_lockEnabled) {
      _presentLockScreen();
    }
  }

  Future<void> _presentLockScreen() async {
    if (_lockRouteVisible || !_lockEnabled) return;
    _lockRouteVisible = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AppLockScreen(
          onUnlocked: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    _lockRouteVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const MainScreen();
  }
}
