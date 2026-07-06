import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/company_setup/presentation/company_setup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Stream-to-Listenable converter helper class for GoRouter reactive redirects.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider managing the global application router instance.
final routerProvider = Provider<GoRouter>((ref) {
  // Listen to Auth State changes to trigger router redirects
  final authStateStream = ref.watch(authRepositoryProvider).authStateChanges;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authStateStream),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/company-setup',
        builder: (context, state) => const CompanySetupScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplashing = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/company-setup';

      // 1. If we are on the splash screen, do not redirect. Let it manage state transitions.
      if (isSplashing) {
        return null;
      }

      // 2. If the user is NOT authenticated, force login screen
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 3. User authenticated, check company setup onboarding mapping
      final hasCompany = user.companyId != null && user.companyId!.isNotEmpty;

      if (!hasCompany) {
        // Must complete onboarding/setup first
        return isOnboarding ? null : '/company-setup';
      }

      // 4. Authenticated & Onboarded: Redirect away from login / onboarding to dashboard
      if (isLoggingIn || isOnboarding) {
        return '/dashboard';
      }

      // Default: proceed to requested route
      return null;
    },
  );
});
