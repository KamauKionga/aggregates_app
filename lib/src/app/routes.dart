import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/phone_otp_screen.dart';
import '../features/auth/presentation/agent_pending_screen.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/domain/models/user_role.dart';
import 'pick_location_wrapper.dart';
import '../features/aggregates/presentation/admin_pricing_screen.dart';
import '../features/quarry/presentation/admin_reassignment_screen.dart';
import '../features/trucker/presentation/trucker_dashboard_screen.dart';
import '../features/agent/presentation/agent_dashboard_screen.dart';
import '../features/orders/presentation/buyer_tracking_screen.dart';
import '../features/reports/presentation/admin_eod_reports_screen.dart';
import '../features/admin/presentation/admin_panel_screen.dart';
import '../features/admin/presentation/admin_users_screen.dart';
import '../features/admin/presentation/admin_wallets_screen.dart';
import '../features/admin/presentation/admin_disputes_screen.dart';

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  String? redirectLogic(BuildContext context, GoRouterState state) {
    final loc = state.location;

    return authState.maybeWhen(
      data: (user) {
        if (user == null) {
          // Unauthenticated: allow auth routes, otherwise redirect to sign-in
          if (loc.startsWith('/auth')) return null;
          return '/auth/sign-in';
        }

        // If user is agent but not approved, restrict to pending page
        if (user.role == UserRole.agent && user.agentApproved == false) {
          if (loc == '/agent/pending') return null;
          return '/agent/pending';
        }

        // Authenticated and allowed: prevent going back to auth pages
        if (loc.startsWith('/auth')) return '/app';
        return null;
      },
      orElse: () => null,
    );
  }

  return GoRouter(
    initialLocation: '/auth/sign-in',
    debugLogDiagnostics: true,
    refreshListenable: _GoRouterRefreshStream(
      ref.watch(authStateChangesProvider.stream),
    ),
    redirect: redirectLogic,
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/app'),
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/phone-otp',
        builder: (context, state) => const PhoneOtpScreen(),
      ),
      GoRoute(
        path: '/agent/pending',
        builder: (context, state) => const AgentPendingScreen(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('App Home (stub)'))),
      ),
      GoRoute(
        path: '/admin/pricing',
        builder: (context, state) => const AdminPricingScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.admin) return '/app';
          return null;
        },
      ),
      GoRoute(
        path: '/admin/assign-quarry',
        builder: (context, state) => const AdminReassignmentScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.admin) return '/app';
          return null;
        },
      ),
      GoRoute(
        path: '/app/pick-location',
        builder: (context, state) => const PickLocationRouteWrapper(),
      ),
      GoRoute(
        path: '/trucker/dashboard',
        builder: (context, state) => const TruckerDashboardScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.trucker) return '/app';
          return null;
        },
      ),
      GoRoute(
        path: '/agent/dashboard',
        builder: (context, state) => const AgentDashboardScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.agent) return '/app';
          return null;
        },
      ),
      GoRoute(
        path: '/orders/:orderId/track',
        builder: (context, state) =>
            BuyerTrackingScreen(orderId: state.pathParameters['orderId']!),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          return null;
        },
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdminEodReportsScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.admin) return '/app';
          return null;
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPanelScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.admin) return '/app';
          return null;
        },
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.admin) return '/app';
          return null;
        },
      ),
      GoRoute(
        path: '/admin/wallets',
        builder: (context, state) => const AdminWalletsScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.admin) return '/app';
          return null;
        },
      ),
      GoRoute(
        path: '/admin/disputes',
        builder: (context, state) => const AdminDisputesScreen(),
        redirect: (context, state) {
          final user = authState.asData?.value;
          if (user == null) return '/auth/sign-in';
          if (user.role != UserRole.admin) return '/app';
          return null;
        },
      ),
    ],
  );
});
