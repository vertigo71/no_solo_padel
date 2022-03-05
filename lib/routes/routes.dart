import 'package:flutter/material.dart';

import '../pages/admin/admin_page.dart';
import '../pages/logging_page.dart';
import '../pages/main/main_page.dart';
import '../pages/loading.dart';
import '../pages/login.dart';
import '../pages/match/match_page.dart';

class RouteManager {
  static const String loginPage = '/';
  static const String loadingPage = '/loadingPage';
  static const String mainPage = '/mainPage';
  static const String matchPage = '/matchPage';
  static const String logging = '/logging';
  static const String adminPage = '/adminPage';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginPage:
        return MaterialPageRoute(builder: (context) => const Login(), settings: settings);

      case loadingPage:
        return MaterialPageRoute(builder: (context) => const Loading(), settings: settings);

      case mainPage:
        return MaterialPageRoute(builder: (context) => const MainPage(), settings: settings);

      case matchPage:
        return MaterialPageRoute(builder: (context) => const MatchPage(), settings: settings);

      case logging:
        return MaterialPageRoute(builder: (context) => const LoggingPage(), settings: settings);

      case adminPage:
        return MaterialPageRoute(builder: (context) => const AdminPage(), settings: settings);

      default:
        throw const FormatException('Route not found! Check routes again!');
    }
  }
}
