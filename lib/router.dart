import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/home/home_screen.dart';
import 'features/journal/journal_form_screen.dart';
import 'features/journal/journal_screen.dart';
import 'features/map/map_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/place/place_detail_screen.dart';
import 'features/place/review_screen.dart';
import 'features/profile/about_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/safety/sos_screen.dart';
import 'features/trips/trip_detail_screen.dart';
import 'features/trips/trip_form_screen.dart';
import 'features/trips/trip_map_screen.dart';
import 'features/trips/trips_screen.dart';
import 'providers.dart';
import 'shared/app_shell.dart';

/// Re-runs the router's redirect whenever sign-in or profile state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(profileProvider, (_, _) => notifyListeners());
  }
}

const _authPaths = {'/login', '/signup', '/forgot-password'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      if (auth.isLoading) return loc == '/splash' ? null : '/splash';
      final user = auth.value;
      if (user == null) return _authPaths.contains(loc) ? null : '/login';

      final profile = ref.read(profileProvider);
      if (profile.isLoading && !profile.hasValue) return loc == '/splash' ? null : '/splash';
      final onboarded = profile.value?.onboarded ?? false;
      if (!onboarded) return loc == '/onboarding' ? null : '/onboarding';
      if (_authPaths.contains(loc) || loc == '/splash' || loc == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/map', builder: (_, _) => const MapScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/trips', builder: (_, _) => const TripsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/place/:id',
        builder: (_, s) => PlaceDetailScreen(placeId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/place/:id/review',
        builder: (_, s) => ReviewScreen(placeId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/trips/new', builder: (_, _) => const TripFormScreen()),
      GoRoute(
        path: '/trips/:id',
        builder: (_, s) => TripDetailScreen(tripId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/trips/:id/edit',
        builder: (_, s) => TripFormScreen(tripId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/trips/:id/map',
        builder: (_, s) => TripMapScreen(tripId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/journal',
        builder: (_, s) => JournalScreen(tripId: s.uri.queryParameters['tripId']),
      ),
      GoRoute(
        path: '/journal/new',
        builder: (_, s) => JournalFormScreen(tripId: s.uri.queryParameters['tripId']),
      ),
      GoRoute(
        path: '/journal/:id',
        builder: (_, s) => JournalFormScreen(entryId: s.pathParameters['id']),
      ),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/profile/preferences', builder: (_, _) => const OnboardingScreen(editing: true)),
      GoRoute(path: '/sos', builder: (_, _) => const SosScreen()),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
    ],
  );
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.travel_explore, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 16),
            Text(
              'TravelVerse',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
            ),
            const SizedBox(height: 4),
            Text('Discover. Plan. Remember.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 28),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
