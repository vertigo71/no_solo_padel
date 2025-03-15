import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/routes.dart';
import '../models/debug.dart';

final String _classString = 'Initial'.toUpperCase();

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      MyLog.log(_classString, 'User = ${user?.displayName}, ${user?.email}');
      if (user != null) {
        MyLog.log(_classString, 'Showing main page');
        context.pushReplacementNamed(AppRoutes.main);
      } else {
        MyLog.log(_classString, 'Showing login page');
        context.pushReplacementNamed(AppRoutes.login);
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
