import 'package:flutter/material.dart';
import 'app_entry_screen.dart';

/// Splash screen with logo animation and timed navigation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  //Needed for AnimationController
  late AnimationController _controller; //control time
  late Animation<double> _scaleAnimation; //control size
  late Animation<double> _fadeAnimation; //control opticity

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward(); //Starts animation(Goes from 0 ? 1)

    // After a short delay, move to the app entry flow.
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        //User cannot go back to splash
        context,
        PageRouteBuilder(
          //Custom animations(Smooth UX)

          pageBuilder: (context, animation, secondaryAnimation) =>
              const AppEntryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          //Fade effect between screens
          //Uses same animation object

          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  //Prevents memory leaks
  //Stops animation when screen removed

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.85),
              colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 100,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Finance Tracker',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Smart Money Management',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onPrimary.withOpacity(0.9),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 50),
                  CircularProgressIndicator(
                    //Shows loading
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                    strokeWidth: 3,
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

