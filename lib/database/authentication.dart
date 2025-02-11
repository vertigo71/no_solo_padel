import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import '../models/debug.dart';

final String _classString = 'AuthenticationHelper'.toUpperCase();

// TODO: it could be static
class AuthenticationHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get user => _auth.currentUser;

  //SIGN UP METHOD
  static Future signUp({required String email, required String password}) async {
    MyLog.log(_classString, 'signUp $email', level: Level.INFO);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// SIGN IN METHOD
  /// Return null if signedIn
  /// else return Error message
  static Future signIn({required String email, required String password}) async {
    MyLog.log(_classString, 'signIn $email', level: Level.INFO);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _toSpanish(e);
    }
  }

  //SIGN OUT METHOD TODO:repasar
  static Future signOut() async {
    MyLog.log(_classString, 'SignOut');
    await _auth.signOut();
  }

  static Future<String> createUserWithEmailAndPwd({required String email, required String pwd}) async {
    MyLog.log(_classString, 'createUserWithEmailAndPwd $email', level: Level.INFO);

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: pwd);
    } on FirebaseAuthException catch (e) {
      String message = _toSpanish(e);
      if (message.isEmpty) {
        message = 'Error al crear el usuario (error indefinido de la base de datos) \n $e';
      }
      return message;
    } catch (e) {
      return 'Error al crear (error indefinido) \n $e';
    }
    return '';
  }

  static Future<String> updateEmail({required String newEmail, required String actualPwd}) async {
    MyLog.log(_classString, 'updateEmail $newEmail');

    return await _updateEmailOrPwd(actualPwd: actualPwd, newEmail: newEmail);
  }

  static Future<String> updatePwd({required String actualPwd, required String newPwd}) async {
    MyLog.log(_classString, 'updatePwd');
    return await _updateEmailOrPwd(actualPwd: actualPwd, newPwd: newPwd);
  }

  static Future<String> _updateEmailOrPwd({required String actualPwd, String newEmail = '', String newPwd = ''}) async {
    MyLog.log(_classString, '_updateEmailOrPwd $newEmail', level: Level.INFO);

    final String errorField = newPwd.isEmpty ? 'el correo' : 'la contraseña';

    if (user == null) return 'Usuario no conectado';

    // update userAuth
    try {
      UserCredential userCredential = await _getUserCredential(user: user!, actualPwd: actualPwd);

      if (userCredential.user == null) {
        return ('Error al actualizar $errorField (credencial no válida)');
      }

      if (newEmail.isNotEmpty) {
        await userCredential.user!.updateEmail(newEmail); // TODO: deprecated
      } else if (newPwd.isNotEmpty) {
        await userCredential.user!.updatePassword(newPwd);
      }
    } on FirebaseAuthException catch (e) {
      String message = _toSpanish(e);
      if (message.isEmpty) {
        message = 'Error actualizando $errorField (error indefinido de la base de datos) \n $e';
      }
      return message;
    } catch (e) {
      return 'Error actualizando $errorField (error indefinido) \n $e';
    }
    return '';
  }

  static Future<UserCredential> _getUserCredential({required User user, required String actualPwd}) async {
    MyLog.log(_classString, '_getUserCredential $user', level: Level.INFO);

    AuthCredential authCredential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: actualPwd,
    );
    MyLog.log(_classString, '_getUserCredential authcred', myCustomObject: authCredential);
    UserCredential userCredential = await user.reauthenticateWithCredential(authCredential);
    MyLog.log(_classString, '_getUserCredential usercred', myCustomObject: userCredential);

    return userCredential;
  }

  static String _toSpanish(FirebaseAuthException e) {
    MyLog.log(_classString, '_toSpanish ${e.code} $e');
    switch (e.code) {
      case 'email-already-in-use':
        {
          return ('Correo ya existente');
        }
      case 'invalid-email':
        {
          return ('Correo no válido');
        }
      case 'user-disabled':
        {
          return ('Usuario inhabilitado');
        }
      case 'user-not-found':
        {
          return ('Usuario no encontrado');
        }
      case 'wrong-password':
        {
          return ('Contraseña no válida');
        }
      case 'weak-password':
        {
          return ('Contraseña debe de tener más de 6 caracteres');
        }
      default:
        {
          return e.message ?? '';
        }
    }
  }
}
