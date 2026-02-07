import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import 'app_lock_screen.dart';
import 'main_screen.dart';

/// Entry point that applies app-lock before showing main UI.
class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({Key? key}) : super(key: key);

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen>
    with WidgetsBindingObserver {
  // App lock service for PIN/biometric settings and checks.
  final AppLockService _lockService = AppLockService();

  // UI state flags for the lock flow.
  bool _isLoading = true; // Shows loader initially.
  bool _lockEnabled = false; // Whether app lock is ON or OFF.
  bool _lockRouteVisible = false; // Prevent duplicate lock screens.
  bool _shouldLockOnResume = false; // Lock after returning to foreground.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register lifecycle listener.
    _loadLockState(); // Load lock settings from storage.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  // Lock the app when returning from background.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mark that we should lock when the app is backgrounded.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // e.g., phone call or notification overlay.
      _shouldLockOnResume = true;
    }

    if (state == AppLifecycleState.resumed && _shouldLockOnResume) {
      _shouldLockOnResume = false; // Prevent repeated locking.
      if (AppLockService.shouldSkipLock()) {
        // User just unlocked the app; skip once to avoid loops.
        return;
      }
      _refreshLockState(); // Show lock screen if enabled.
    }
  }

  // Load saved lock settings on startup.
  Future<void> _loadLockState() async {
    final settings = await _lockService.loadSettings();
    if (!mounted) return; // Avoid setState after dispose.
    setState(() {
      _lockEnabled = settings.isEnabled;
      _isLoading = false;
    });

    if (_lockEnabled) {
      // Wait for first frame before pushing the lock screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _presentLockScreen();
      });
    }
  }

  // Refresh lock settings when resuming.
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

  // Present lock screen if lock is enabled.
  Future<void> _presentLockScreen() async {
    if (_lockRouteVisible || !_lockEnabled) {
      return; // Prevent double lock screen or when disabled.
    }
    _lockRouteVisible = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true, // Full-screen modal lock screen.
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
