import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:no_solo_padel/pages/misc/page_set_result.dart';
import 'package:no_solo_padel/pages/misc/page_register.dart';

import '../models/debug.dart';
import '../pages/admin/page_admin.dart';
import '../pages/main/page_main.dart';
import '../pages/page_login.dart';
import '../pages/match/page_match.dart';

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
  static const String registerPath = '/register';
  static const String register = 'register';
  static const String setResultPath = '/set_result';
  static const String setResult = 'set_result';
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
            final matchJson = state.extra as Map<String, dynamic>; // Retrieve the argument
            MyLog.log(_classString, 'going to MatchPAge: match=$matchJson');
            return MatchPage(matchJson: matchJson); // Pass it to the widget
          },
          name: AppRoutes.match),
      GoRoute(
          path: AppRoutes.adminPath,
          builder: (BuildContext context, GoRouterState state) => const AdminPage(),
          name: AppRoutes.admin),
      GoRoute(
          path: AppRoutes.registerPath,
          builder: (BuildContext context, GoRouterState state) => const RegisterPage(),
          name: AppRoutes.register),
      GoRoute(
          path: AppRoutes.setResultPath,
          builder: (BuildContext context, GoRouterState state) {
            // never use a complex object as an argument. Back button will not work
            final String matchId = state.extra as String; // Retrieve the argument
            MyLog.log(_classString, 'going to SetResultPAge: match=$matchId');
            return SetResultPage(matchId: matchId); // Pass it to the widget
          },
          name: AppRoutes.setResult),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page Not Found')),
    ),
  );
}
