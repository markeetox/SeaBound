import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/alerts_screen.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/about_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/public_profile_screen.dart';
import '../features/spots/spot_detail_screen.dart';
import '../features/spots/spot_form_screen.dart';
import '../features/spots/spots_screen.dart';
import '../features/trips/trip_detail_screen.dart';
import '../features/trips/trip_form_screen.dart';
import '../features/trips/trips_screen.dart';
import 'home_shell_screen.dart';

const String initialTabLocation = '/home';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialTabLocation,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final user = authState.asData?.value;
      final isLoggedIn = user != null;

      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isAuthRoute = isLoggingIn || isSigningUp;

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute) {
        return initialTabLocation;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/user/:uid',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return PublicProfileScreen(userId: uid);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trips',
                builder: (context, state) => const TripsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const TripFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final tripId = state.pathParameters['id']!;
                      return TripDetailScreen(tripId: tripId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final tripId = state.pathParameters['id']!;
                          return TripFormScreen(tripId: tripId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/spots',
                builder: (context, state) => const SpotsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SpotFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final spotId = state.pathParameters['id']!;
                      return SpotDetailScreen(spotId: spotId);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final spotId = state.pathParameters['id']!;
                          return SpotFormScreen(spotId: spotId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alerts',
                builder: (context, state) => const AlertsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
