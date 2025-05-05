import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/md_debug.dart';
import '../pages/admin/home_admin.dart';
import '../pages/main/home_main.dart';
import '../pages/login.dart';
import '../pages/main/information/info_user.dart';
import '../pages/match/home_match.dart';
import '../pages/misc/register.dart';

final String _classString = 'Routes'.toUpperCase();

// Define route names (recommended):
class AppRoutes {
  static const String kLoginPath = '/login';
  static const String kLogin = 'login';
  static const String kMainPath = '/main';
  static const String kMain = 'main';
  static const String kMatchPath = '/match';
  static const String kMatch = 'match';
  static const String kAdminPath = '/admin';
  static const String kAdmin = 'admin';
  static const String kRegisterPath = '/register';
  static const String kRegister = 'register';
  static const String kInfoUserPath = '/info_user';
  static const String kInfoUser = 'info_user';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.kLoginPath,
    routes: <RouteBase>[
      GoRoute(
          path: AppRoutes.kLoginPath,
          builder: (BuildContext context, GoRouterState state) => const LoginPage(),
          name: AppRoutes.kLogin // Optional: give the route a name
          ),
      GoRoute(
          path: AppRoutes.kMainPath,
          builder: (BuildContext context, GoRouterState state) => const MainPage(),
          name: AppRoutes.kMain),
      GoRoute(
          path: AppRoutes.kMatchPath,
          builder: (BuildContext context, GoRouterState state) {
            // never use a complex object as an argument
            // back button will not work
            final matchJson = state.extra as Map<String, dynamic>; // Retrieve the argument
            MyLog.log(_classString, 'going to MatchPAge: match=$matchJson');
            return MatchPage(matchJson: matchJson); // Pass it to the widget
          },
          name: AppRoutes.kMatch),
      GoRoute(
          path: AppRoutes.kAdminPath,
          builder: (BuildContext context, GoRouterState state) => const AdminPage(),
          name: AppRoutes.kAdmin),
      GoRoute(
          path: AppRoutes.kRegisterPath,
          builder: (BuildContext context, GoRouterState state) => const RegisterPage(),
          name: AppRoutes.kRegister),
      GoRoute(
          path: AppRoutes.kInfoUserPath,
          builder: (BuildContext context, GoRouterState state) {
            // never use a complex object as an argument
            // back button will not work
            final args = (state.extra as List<dynamic>).cast<String>(); // Retrieve the argument
            MyLog.log(_classString, 'going to InfoUserPanel: args=$args');
            return InfoUserPanel(args: args); // Pass it to the widget
          },
          name: AppRoutes.kInfoUser),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page Not Found')),
    ),
  );
}
