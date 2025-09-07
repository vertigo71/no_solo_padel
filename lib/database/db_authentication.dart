import 'package:firebase_auth/firebase_auth.dart';
import 'package:simple_logger/simple_logger.dart';

import '../models/md_debug.dart';
import '../models/md_exception.dart';

final String _classString = '<db> AuthenticationHelper'.toLowerCase();

class AuthenticationHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get user => _auth.currentUser;

  //SIGN UP METHOD
  static Future<String?> signUp({required String email, required String password}) async {
    MyLog.log(_classString, 'signUp $email');
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      throw MyException('Error al crear usuario', e: e);
    }
  }

  /// SIGN IN METHOD
  /// Return null if signedIn
  /// else return Error message
  static Future<String?> signIn({required String email, required String password}) async {
    MyLog.log(_classString, 'signIn $email language=${_auth.languageCode}');

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Successful sign-in
      MyLog.setLoggedUserId(_auth.currentUser?.uid ?? '');
      return null;
    } on FirebaseAuthException catch (e) {
      return _toSpanish(e);
    } catch (e) {
      throw MyException('Error al iniciar sesión', e: e);
    }
  }

  //SIGN OUT METHOD
  static Future<void> signOut() async {
    MyLog.log(_classString, 'SignOut');
    await _auth.signOut();
    MyLog.setLoggedUserId('');
  }

  /// Creates a new user in Firestore using email and password authentication.
  ///
  /// This function attempts to create a new user with the provided email and password
  /// using Firebase Authentication.  It handles potential `FirebaseAuthException` errors
  /// and other exceptions, returning a localized error message (Spanish) if the
  /// creation fails.
  ///
  /// Returns:
  ///   - A Spanish error message (`String`) if user creation fails.  The message
  ///     will attempt to provide specific details about the error, including
  ///     handling `FirebaseAuthException`s and other exceptions.
  ///   - An empty string (`''`) if user creation is successful.
  ///
  static Future<String> createUserWithEmailAndPwd({required String email, required String pwd}) async {
    MyLog.log(_classString, 'createUserWithEmailAndPwd $email');

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: pwd);
    } on FirebaseAuthException catch (e) {
      String message = _toSpanish(e);
      if (message.isEmpty) {
        message = 'Error al crear usuario $email (error indefinido de la base de datos) \n ${e.toString()}';
      }
      return message;
    } catch (e) {
      return 'Error al crear usuario $email (error indefinido) \n'
          '${e.toString()}';
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
    MyLog.log(_classString, '_updateEmailOrPwd $newEmail');

    final String errorField = newPwd.isEmpty ? 'el correo' : 'la contraseña';

    if (user == null) return 'Usuario no conectado';

    // update userAuth
    try {
      UserCredential userCredential = await _getUserCredential(user: user!, actualPwd: actualPwd);

      if (userCredential.user == null) {
        return 'Error al actualizar $errorField (credencial no válida)';
      }

      if (newEmail.isNotEmpty) {
        throw MyException('La función de actualizar el usuario está pendiente de elaboración', level: Level.SEVERE);
        // await userCredential.user!.updateEmail(newEmail); // TODO: deprecated
      } else if (newPwd.isNotEmpty) {
        await userCredential.user!.updatePassword(newPwd);
      }
    } on FirebaseAuthException catch (e) {
      String message = _toSpanish(e);
      if (message.isEmpty) {
        message = 'Error actualizando $errorField (error indefinido de la base de datos) \n ${e.toString()}';
      }
      return message;
    } catch (e) {
      return 'Error actualizando $errorField (error indefinido) \n ${e.toString()}';
    }
    return '';
  }

  static Future<UserCredential> _getUserCredential({required User user, required String actualPwd}) async {
    MyLog.log(_classString, '_getUserCredential $user');

    AuthCredential authCredential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: actualPwd,
    );
    MyLog.log(_classString, '_getUserCredential authcred', myCustomObject: authCredential, indent: true);
    UserCredential userCredential = await user.reauthenticateWithCredential(authCredential);
    MyLog.log(_classString, '_getUserCredential usercred', myCustomObject: userCredential, indent: true);

    return userCredential;
  }

  /// Converts a `FirebaseAuthException` to a localized Spanish error message.
  ///
  /// This function takes a `FirebaseAuthException` object and attempts to convert
  /// it to a user-friendly Spanish error message.  It handles common Firebase
  /// Authentication error codes and provides corresponding Spanish translations.
  /// If the error code is not recognized, it returns a generic error message,
  /// including the original Firebase error code for debugging purposes.
  ///
  /// Parameters:
  ///   - `e`: The `FirebaseAuthException` to convert.
  ///
  /// Returns:
  ///   - A localized Spanish error message (`String`). If the error code is not
  ///     recognized, a generic message including the Firebase error code is returned.
  static String _toSpanish(FirebaseAuthException e) {
    MyLog.log(_classString, '_toSpanish ${e.code} ${e.toString()}', level: Level.FINE);

    switch (e.code) {
      case 'email-already-in-use':
        return 'Correo ya existente';
      case 'invalid-email':
        return 'Correo no válido';
      case 'user-disabled':
        return 'Usuario inhabilitado';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña no válida';
      case 'weak-password':
        return 'Contraseña debe de tener más de 6 caracteres';
      default:
        return 'Error de autenticación: \n${e.code} \n(mensaje: ${e.message ?? 'No disponible'})';
    }
  }
}
