import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../routes/routes.dart';
import '../models/debug.dart';

final String _classString = '<as> AuthService'.toUpperCase();

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoRouter _router;

  AuthenticationService(this._router) {
    _auth.authStateChanges().listen((User? user) {
      //The authStateChanges callback is executed after the MaterialApp.router widget has been built,
      // so a valid BuildContext is available.
      MyLog.log(_classString, 'User = ${user?.displayName}, ${user?.email}');
      if (user != null) {
        MyLog.log(_classString, 'Showing main page');
        _router.pushReplacementNamed(AppRoutes.main);
      } else {
        MyLog.log(_classString, 'Showing login page');
        _router.pushReplacementNamed(AppRoutes.login);
      }
    });
  }
}
