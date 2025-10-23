import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:molo/providers/auth_provider.dart';
// import 'package:patient/screens/home_screen.dart'; // No longer directly navigating here
import 'package:molo/routing/app_router.dart'; // Import AppRouter
import 'package:molo/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStateAndNavigate();
  }

  Future<void> _checkAuthStateAndNavigate() async {
    // Ensure the AuthProvider is initialized and has had a chance to check auth state
    // A small delay can help if AuthProvider's initial check is asynchronous
    // and not immediately reflected.
    // However, AuthProvider's constructor already calls checkAuthState(),
    // so direct listening or a one-shot future might be better.

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Option 1: Use a short delay if initial state isn't ready immediately.
    // await Future.delayed(const Duration(seconds: 1)); // Adjust delay as needed

    // Option 2: More robustly, listen for the first non-loading state.
    // This requires AuthProvider to reliably set isLoading to false after initial check.

    // Define the listener callback
    _authListener = () {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isLoading && mounted) {
        // Force load user profile for better UX if authenticated
        if (auth.isAuthenticated) {
          auth.loadUserProfile(forceRefresh: true).then((_) {
            if (kDebugMode) {
              print('[SplashScreen] User profile loaded: ${auth.userProfile}');
            }
          }).catchError((error) {
            if (kDebugMode) {
              print('[SplashScreen] Error loading user profile: $error');
            }
          });
        }
        _navigateToNextScreen(auth.isAuthenticated);
        // Remove listener after first successful navigation to prevent multiple navigations
        auth.removeListener(_authListener!);
        _authListener = null; // Clear the stored listener
      }
    };

    if (authProvider.isLoading) {
      // If still loading, add the listener.
      authProvider.addListener(_authListener!);
      // It's possible checkAuthState is still running or hasn't emitted yet.
      // If AuthProvider's checkAuthState is quick and synchronous for the initial user state,
      // this listener might fire very quickly or after a slight delay.
    } else {
      // If not loading, the state should be current.
      // Schedule navigation for after the current build cycle to avoid errors.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Force load user profile for better UX if authenticated
        if (authProvider.isAuthenticated) {
          authProvider.loadUserProfile(forceRefresh: true).then((_) {
            if (kDebugMode) {
              print('[SplashScreen] User profile loaded: ${authProvider.userProfile}');
            }
          }).catchError((error) {
            if (kDebugMode) {
              print('[SplashScreen] Error loading user profile: $error');
            }
          });
        }
        _navigateToNextScreen(authProvider.isAuthenticated);
      });
    }
  }

  VoidCallback? _authListener;
  
  void _navigateToNextScreen(bool isAuthenticated) {
    if (!mounted) return;

    // Ensure navigation happens only once by checking if listener is still active or by other means
    // For splash screen, pushReplacement is typical.
    if (isAuthenticated) {
      // Navigate to MainScreen (via homeRoute logic in AppRouter)
      AppRouter.navigateToHome(context);
    } else {
      // Navigate to LoginScreen using AppRouter
      AppRouter.navigateToLogin(context);
    }
  }

  @override
  void dispose() {
    // Remove listener if it's still attached
    if (_authListener != null) {
      Provider.of<AuthProvider>(context, listen: false).removeListener(_authListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The logic in initState and the listener should handle navigation.
    // The build method just shows the loading indicator.
    return const Scaffold(
      // appBar: AppBar(title: Text("Splash")), // Keep or remove based on custom AppBar plans
      body: LoadingWidget(
        size: 60, // Larger loading indicator for splash
      ),
    );
  }
}
