import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/app_providers.dart';

import '../../presentation/home/home_screen.dart';
import '../../presentation/expenses/expenses_screen.dart';
import '../../presentation/goals/goals_screen.dart';
import '../../presentation/investments/investments_screen.dart';
import '../../presentation/ai_coach/ai_coach_screen.dart';
import '../../presentation/ai_coach/chat_session_screen.dart';
import '../../presentation/ai_coach/chat_history_screen.dart';
import '../../presentation/design_system/components/bottom_nav_scaffold.dart';

import '../../presentation/splash/splash_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/accounts/account_dashboard_screen.dart';
import '../../presentation/notifications/notification_center_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/transactions/transaction_history_screen.dart';
import '../../presentation/expenses/expenses_history_screen.dart';

import '../../data/repositories/auth_repository.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/signup_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isSplash = state.uri.toString() == '/splash';
      if (isSplash) return null;

      final authState = ref.read(authStateProvider);
      final userProfileAsync = ref.read(userProfileProvider);

      final isAuthScreen = state.uri.toString() == '/login' || state.uri.toString() == '/signup';
      final isGoingToOnboarding = state.uri.toString() == '/onboarding';

      return authState.when(
        data: (user) {
          if (user == null) {
            // Not logged in
            return isAuthScreen ? null : '/login';
          }
          
          debugPrint('AppRouter: User authenticated (UID: ${user.uid})');

          return userProfileAsync.when(
            data: (userProfile) {
              debugPrint('AppRouter: Onboarding status fetched. completed: ${userProfile?.onboardingCompleted}');
              
              if (isAuthScreen) {
                if (userProfile != null && userProfile.onboardingCompleted) {
                  debugPrint('AppRouter: Navigating to Home from Auth Screen');
                  return '/home';
                } else {
                  debugPrint('AppRouter: Navigating to Onboarding from Auth Screen');
                  return '/onboarding';
                }
              }

              if (userProfile == null || !userProfile.onboardingCompleted) {
                if (!isGoingToOnboarding) {
                  debugPrint('AppRouter: Navigating to Onboarding (not completed)');
                  return '/onboarding';
                }
                return null; // Stay on onboarding
              }

              if (userProfile.onboardingCompleted && isGoingToOnboarding) {
                debugPrint('AppRouter: Navigating to Home (already completed)');
                return '/home';
              }

              return null; // Stay on current screen
            },
            loading: () {
              debugPrint('AppRouter: Loading user profile...');
              return null; // Stay where we are while loading
            },
            error: (e, s) {
              debugPrint('AppRouter: Error loading profile: $e');
              return '/login';
            },
          );
        },
        loading: () => null, // Stay where we are while loading
        error: (_, __) => '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/accounts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountDashboardScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/transactions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'] ?? 'All';
          return TransactionHistoryScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        path: '/expenses/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpensesHistoryScreen(),
      ),
      GoRoute(
        path: '/ai_coach/session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatSessionScreen(),
      ),
      GoRoute(
        path: '/ai_coach/session/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatSessionScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: '/ai_coach/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChatHistoryScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return BottomNavScaffold(currentPath: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/investments',
            builder: (context, state) => const InvestmentsScreen(),
          ),
          GoRoute(
            path: '/ai_coach',
            builder: (context, state) => const AiCoachScreen(),
          ),
        ],
      ),
    ],
  );
});
