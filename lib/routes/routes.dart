import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:no_solo_padel_dev/models/match_model.dart';

import '../pages/admin/admin_page.dart';
import '../pages/main/main_page.dart';
import '../pages/loading.dart';
import '../pages/login.dart';
import '../pages/match/match_page.dart';

// Define route names (recommended):
class AppRoutes {
  static const String loginPath = '/login';
  static const String login = 'login';
  static const String loadingPath = '/loading';
  static const String loading = 'loading';
  static const String mainPath = '/main';
  static const String main = 'main';
  static const String matchPath = '/match';
  static const String match = 'match';
  static const String adminPath = '/admin';
  static const String admin = 'admin';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.loginPath,
    routes: <RouteBase>[
      GoRoute(
          path: AppRoutes.loginPath,
          builder: (BuildContext context, GoRouterState state) => const LoginPage(),
          name: AppRoutes.login // Optional: give the route a name
          ),
      GoRoute(
          path: AppRoutes.loadingPath,
          builder: (BuildContext context, GoRouterState state) => const LoadingPage(),
          name: AppRoutes.loading),
      GoRoute(
          path: AppRoutes.mainPath,
          builder: (BuildContext context, GoRouterState state) => const MainPage(),
          name: AppRoutes.main),
      GoRoute(
          path: AppRoutes.matchPath,
          builder: (BuildContext context, GoRouterState state) {
            final match = state.extra as MyMatch; // Retrieve the argument
            return MatchPage(match: match); // Pass it to the widget
          },
          name: AppRoutes.match),
      GoRoute(
          path: AppRoutes.adminPath,
          builder: (BuildContext context, GoRouterState state) => const AdminPage(),
          name: AppRoutes.admin),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page Not Found')),
    ),
  );
}

