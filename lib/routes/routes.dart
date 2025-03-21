import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/debug.dart';
import '../pages/admin/admin_page.dart';
import '../pages/main/main_page.dart';
import '../pages/login.dart';
import '../pages/match/match_page.dart';

final String _classString = 'Routes'.toUpperCase();

// Define route names (recommended):
class AppRoutes {
  static const String loginPath = '/login';
  static const String login = 'login';
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
          path: AppRoutes.mainPath,
          builder: (BuildContext context, GoRouterState state) => const MainPage(),
          name: AppRoutes.main),
      GoRoute(
          path: AppRoutes.matchPath,
          builder: (BuildContext context, GoRouterState state) {
            // never use a complex object as an argument
            // back button will not work
            final matchId = state.extra as String; // Retrieve the argument
            MyLog.log(_classString, 'going to MatchPAge: match=$matchId');
            return MatchPage(matchIdStr: matchId); // Pass it to the widget
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
