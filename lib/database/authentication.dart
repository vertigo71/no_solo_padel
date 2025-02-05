import 'package:firebase_auth/firebase_auth.dart';

import '../models/debug.dart';

final String _classString = 'AuthenticationHelper'.toUpperCase();

// TODO: it could be static
class AuthenticationHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  //SIGN UP METHOD
  Future signUp({required String email, required String password}) async {
    MyLog().log(_classString, 'signUp $email', debugType: DebugType.warning);
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

  //SIGN IN METHOD
  Future signIn({required String email, required String password}) async {
    MyLog().log(_classString, 'signIn $email', debugType: DebugType.warning);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _toSpanish(e);
    }
  }

  //SIGN OUT METHOD
  Future signOut({required Function() signedOutFunction}) async {
    MyLog().log(_classString, 'SignOut begin', debugType: DebugType.warning);
    await signedOutFunction();
    MyLog().log(_classString, 'SignOut listeners deleted');
    await _auth.signOut();
    MyLog().log(_classString, 'SignOut ended', debugType: DebugType.warning);
  }

  Future<String> createUserWithEmailAndPwd({required String email, required String pwd}) async {
    MyLog().log(_classString, 'createUserWithEmailAndPwd $email', debugType: DebugType.warning);

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

  Future<String> updateEmail({required String newEmail, required String actualPwd}) async {
    MyLog().log(_classString, 'updateEmail $newEmail');

    return await _updateEmailOrPwd(actualPwd: actualPwd, newEmail: newEmail);
  }

  Future<String> updatePwd({required String actualPwd, required String newPwd}) async {
    MyLog().log(_classString, 'updatePwd');
    return await _updateEmailOrPwd(actualPwd: actualPwd, newPwd: newPwd);
  }

  Future<String> _updateEmailOrPwd({required String actualPwd, String newEmail = '', String newPwd = ''}) async {
    MyLog().log(_classString, '_updateEmailOrPwd $newEmail', debugType: DebugType.warning);

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

  Future<UserCredential> _getUserCredential({required User user, required String actualPwd}) async {
    MyLog().log(_classString, '_getUserCredential $user', debugType: DebugType.warning);

    AuthCredential authCredential = EmailAuthProvider.credential(
      email: user.email ?? '',
      password: actualPwd,
    );
    MyLog().log(_classString, '_getUserCredential authcred', myCustomObject: authCredential);
    UserCredential userCredential = await user.reauthenticateWithCredential(authCredential);
    MyLog().log(_classString, '_getUserCredential usercred', myCustomObject: userCredential);

    return userCredential;
  }

  String _toSpanish(FirebaseAuthException e) {
    MyLog().log(_classString, '_toSpanish ${e.code} $e');
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
