import 'dart:async';

import 'package:collection/collection.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/debug.dart';
import '../models/register_model.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/date.dart';
import 'fields.dart';

final String _classString = 'FirebaseHelper'.toUpperCase();

class FirebaseHelper {
  final FirebaseFirestore _instance = FirebaseFirestore.instance;
  StreamSubscription? _usersListener;
  StreamSubscription? _matchesListener;
  StreamSubscription? _paramListener;

  FirebaseHelper() {
    MyLog().log(_classString, 'Building');
  }

  // stream of messages registered
  Stream<List<RegisterModel>>? getRegisterStream(int fromDaysAgo) {
    MyLog().log(_classString, 'getRegisterStream');
    try {
      return _instance
          .collection(strDB(DBFields.register))
          .where(FieldPath.documentId,
              isGreaterThan: Date.now().subtract(Duration(days: fromDaysAgo)).toYyyyMMdd())
          .snapshots()
          .map((QuerySnapshot querySnapshot) => _getRegisterArray(querySnapshot));
    } catch (e) {
      MyLog().log(_classString, 'getRegisterStream', exception: e, debugType: DebugType.error);
      return null;
    }
  }

  List<RegisterModel> _getRegisterArray(QuerySnapshot querySnapshot) {
    return querySnapshot.docs
        .map((DocumentSnapshot documentSnapshot) => RegisterModel.list(
              date: Date(DateTime.parse(documentSnapshot.id)),
              timedMsgList:
                  ((documentSnapshot.data() as dynamic)[strDB(DBFields.registerMessage)] ?? [])
                      .cast<String>(),
            ))
        .toList();
  }

  Future<void> uploadUser(MyUser myUser) async {
    MyLog().log(_classString, 'uploadUser $myUser');
    return _instance.collection(strDB(DBFields.users)).doc(myUser.userId).set({
      strDB(DBFields.name): myUser.name,
      strDB(DBFields.email): myUser.email,
      strDB(DBFields.userType): myUser.userType.index,
      if (myUser.lastLogin != null) strDB(DBFields.lastLogin): myUser.lastLogin!.toYyyyMMdd(),
      strDB(DBFields.loginCount): myUser.loginCount,
    }).catchError((onError) {
      MyLog().log(_classString, 'uploadUser ', exception: onError, debugType: DebugType.error);
    });
  }

  // core = comment + isOpen + courtNAmes (all except players)
  Future<void> uploadMatch(
      {required MyMatch match, required bool updateCore, required bool updatePlayers}) async {
    MyLog().log(_classString, 'uploadMatch $match');

    Map<String, dynamic> uploadMap = {
      if (updateCore) strDB(DBFields.comment): match.comment,
      if (updateCore) strDB(DBFields.isOpen): match.isOpen,
      if (updateCore) strDB(DBFields.courtNames): match.courtNames.toList(),
      if (updatePlayers)
        strDB(DBFields.players): match.players.map((player) => player.userId).toList(),
    };

    return _instance
        .collection(strDB(DBFields.matches))
        .doc(match.date.toYyyyMMdd())
        .update(uploadMap)
        .catchError((onError) => _instance
            .collection(strDB(DBFields.matches))
            .doc(match.date.toYyyyMMdd())
            .set(uploadMap))
        .catchError((onError) => MyLog().log(_classString, 'uploadMatch',
            myCustomObject: uploadMap, exception: onError, debugType: DebugType.error));
  }

  // return false if existed, true if created
  Future<bool> createMatchIfNotExists({required MyMatch match}) async {
    bool exists =
        await doesDocExist(collection: strDB(DBFields.matches), doc: match.date.toYyyyMMdd());
    MyLog().log(_classString, 'createMatchIfNotExists exists $exists $match');
    if (exists) return false;

    await uploadMatch(match: match, updateCore: true, updatePlayers: true);

    return true;
  }

  Future<void> uploadRegister({required RegisterModel register}) async {
    MyLog().log(_classString, 'uploadRegister $register');

    var data = {
      strDB(DBFields.registerMessage): FieldValue.arrayUnion(register.msgList),
    };

    return _instance
        .collection(strDB(DBFields.register))
        .doc(register.date.toYyyyMMdd())
        .update(data)
        .catchError((e) => _instance
            .collection(strDB(DBFields.register))
            .doc(register.date.toYyyyMMdd())
            .set(data))
        .catchError((onError) => MyLog().log(_classString, 'uploadRegister',
            myCustomObject: data, exception: onError, debugType: DebugType.error));
  }

  Future<void> uploadParameters({required List<String> parameters}) async {
    MyLog().log(_classString, 'uploadParameters $parameters');

    Map<String, String> data = {};
    for (int index = 0; index < parameters.length; index++) {
      data[ParametersEnum.values[index].name] = parameters[index];
    }
    MyLog().log(_classString, 'uploadParameters data', myCustomObject: data);

    return _instance
        .collection(strDB(DBFields.parameters))
        .doc(strDB(DBFields.parameters))
        .set(data)
        .catchError((onError) => MyLog().log(_classString, 'uploadParameters',
            myCustomObject: data, exception: onError, debugType: DebugType.error));
  }

  Future<bool> doesDocExist({required String collection, required String doc}) async {
    return _instance.collection(collection).doc(doc).get().then((doc) => doc.exists);
  }

  Future<MyParameters?> downloadParameters() async {
    MyLog().log(_classString, 'downloadParameters');

    // download parameters
    QuerySnapshot<Map<String, dynamic>>? querySnapShot;
    try {
      querySnapShot = await _instance.collection(strDB(DBFields.parameters)).get();
      return _downloadParameters(snapshot: querySnapShot);
    } catch (e) {
      MyLog().log(_classString, 'downloadParameters',
          myCustomObject: querySnapShot, exception: e, debugType: DebugType.error);
    }
    return null;
  }

  MyParameters? _downloadParameters({
    required QuerySnapshot snapshot,
  }) {
    MyLog().log(_classString, '_downloadParameters');
    for (var doc in snapshot.docs) {
      if (doc.data() == null) throw 'Error en la base de datos de parametros';

      if (doc.id == DBFields.parameters.name) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        MyParameters myParameters = MyParameters();
        try {
          myParameters.setValue(
              ParametersEnum.matchDaysToView, data[strDB(DBFields.matchDaysToView)]);
          myParameters.setValue(ParametersEnum.registerDaysAgoToView,
              data[strDB(DBFields.registerDaysAgoToView)] ?? '1');
          myParameters.setValue(
              ParametersEnum.matchDaysKeeping, data[strDB(DBFields.matchDaysKeeping)]);
          myParameters.setValue(
              ParametersEnum.registerDaysKeeping, data[strDB(DBFields.registerDaysKeeping)]);
          myParameters.setValue(
              ParametersEnum.fromDaysAgoToTelegram, data[strDB(DBFields.fromDaysAgoToTelegram)]);
          myParameters.setValue(
              ParametersEnum.defaultCommentText, data[strDB(DBFields.defaultCommentText)]);
          myParameters.setValue(ParametersEnum.minDebugLevel, data[strDB(DBFields.minDebugLevel)]);
          myParameters.setValue(ParametersEnum.weekDaysMatch, data[strDB(DBFields.weekDaysMatch)]);
          myParameters.setValue(ParametersEnum.showLog, data[strDB(DBFields.showLog)]);
        } catch (e) {
          MyLog().log(_classString, '_downloadParameters',
              myCustomObject: data, exception: e, debugType: DebugType.error);
        }
        return myParameters;
      }
    }
    return null;
  }

  Future<List<MyUser>> downloadUsers() async {
    MyLog().log(_classString, 'downloadUsers');

    // download users
    QuerySnapshot? querySnapshot;
    List<MyUser> users = [];
    try {
      querySnapshot = await _instance.collection(strDB(DBFields.users)).get();
      users = _downloadUsers(snapshot: querySnapshot);
    } catch (e) {
      MyLog().log(_classString, 'downloadUsers',
          myCustomObject: querySnapshot, exception: e, debugType: DebugType.error);
    }
    return users;
  }

  List<MyUser> _downloadUsers({required QuerySnapshot snapshot}) {
    List<MyUser> users = [];
    MyLog().log(_classString, '_downloadUsers Number of users = ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      if (doc.data() == null) throw 'Error en la base de datos de usuarios';
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      MyUser user = MyUser();
      try {
        Date? lastLogin;
        if (data[strDB(DBFields.lastLogin)] != null) {
          lastLogin = Date(DateTime.parse(data[strDB(DBFields.lastLogin)]));
        }

        user = MyUser(
          name: data[strDB(DBFields.name)],
          email: data[strDB(DBFields.email)],
          userType: UserType.values[data[strDB(DBFields.userType)]],
          lastLogin: lastLogin,
          loginCount: data[strDB(DBFields.loginCount)] ?? 0,
          userId: doc.id,
        );
      } catch (e) {
        MyLog().log(_classString, '_downloadUsers formato incorrecto',
            myCustomObject: user, exception: e, debugType: DebugType.error);
      }

      if (user.hasNotEmptyFields()) {
        users.add(user);
      } else {
        MyLog().log(
            _classString, '_downloadUsers Formato de usuario incorrecto en la Base de Datos',
            debugType: DebugType.error, myCustomObject: user);
      }
    }

    return users;
  }

  Future<List<MyMatch>> downloadMatches({
    required Date fromDate,
    required int numDays,
    required List<MyUser> Function() availableUsers,
  }) async {
    MyLog().log(_classString, 'downloadMatches');
    // download matches
    List<MyMatch> matches = [];
    QuerySnapshot? querySnapshot;
    try {
      querySnapshot = await _instance
          .collection(strDB(DBFields.matches))
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMMdd())
          .where(FieldPath.documentId,
              isLessThan: Date.now().add(Duration(days: numDays)).toYyyyMMdd())
          .get();
      matches = _downloadMatches(snapshot: querySnapshot, availableUsers: availableUsers);
    } catch (e) {
      MyLog().log(_classString, 'downloadMatches',
          myCustomObject: querySnapshot, exception: e, debugType: DebugType.error);
    }

    return matches;
  }

  List<MyMatch> _downloadMatches({
    required QuerySnapshot snapshot,
    required List<MyUser> Function() availableUsers,
  }) {
    List<MyMatch> matches = [];
    MyLog().log(_classString, '_downloadMatches Number of matches = ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      if (doc.data() == null) throw 'Error en la base de datos de partidos';
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Date date = Date(DateTime.parse(doc.id));
      MyMatch match = _createMatchFromMap(date: date, data: data, availableUsers: availableUsers);
      matches.add(match);
    }
    return matches;
  }

  Future<void> createListeners({
    required Date fromDate,
    required int numDays,
    required List<MyUser> Function() availableUsers,
    required void Function(MyParameters? parameters) parametersFunction,
    required void Function(List<MyUser> added, List<MyUser> modified, List<MyUser> removed)
        usersFunction,
    required void Function(List<MyMatch> added, List<MyMatch> modified, List<MyMatch> removed)
        matchesFunction,
  }) async {
    await disposeListeners();

    MyLog().log(_classString, 'Building createListeners ');

    // update parameters
    MyParameters? myParameters;
    try {
      _paramListener =
          _instance.collection(strDB(DBFields.parameters)).snapshots().listen((snapshot) {
        MyLog().log(_classString, 'LISTENER parameters started');

        myParameters = _downloadParameters(snapshot: snapshot);
        MyLog().log(_classString, 'LISTENER parameters = $myParameters');
        parametersFunction(myParameters);
      });
    } catch (e) {
      MyLog().log(_classString, 'createListeners parameters',
          myCustomObject: _paramListener, exception: e, debugType: DebugType.error);
    }

    // update users
    try {
      _usersListener = _instance.collection(strDB(DBFields.users)).snapshots().listen((snapshot) {
        MyLog().log(_classString, 'LISTENER users started');

        List<MyUser> addedUsers = [];
        List<MyUser> modifiedUsers = [];
        List<MyUser> removedUsers = [];
        _downloadChangedUsers(
          snapshot: snapshot,
          addedUsers: addedUsers,
          modifiedUsers: modifiedUsers,
          removedUsers: removedUsers,
        );
        usersFunction(addedUsers, modifiedUsers, removedUsers);
      });
    } catch (e) {
      MyLog().log(_classString, 'createListeners users',
          myCustomObject: _usersListener, exception: e, debugType: DebugType.error);
    }

    // update matches
    try {
      _matchesListener = _instance
          .collection(strDB(DBFields.matches))
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMMdd())
          .where(FieldPath.documentId,
              isLessThan: Date.now().add(Duration(days: numDays)).toYyyyMMdd())
          .snapshots()
          .listen((snapshot) {
        MyLog().log(_classString, 'LISTENER matches started');

        List<MyMatch> addedMatches = [];
        List<MyMatch> modifiedMatches = [];
        List<MyMatch> removedMatches = [];
        _downloadChangedMatches(
          snapshot: snapshot,
          availableUsers: availableUsers,
          addedMatches: addedMatches,
          modifiedMatches: modifiedMatches,
          removedMatches: removedMatches,
        );
        MyLog().log(_classString, 'createListeners added', myCustomObject: addedMatches);
        MyLog().log(_classString, 'createListeners modified', myCustomObject: modifiedMatches);
        MyLog().log(_classString, 'createListeners removed', myCustomObject: removedMatches);

        matchesFunction(addedMatches, modifiedMatches, removedMatches);
      });
    } catch (e) {
      MyLog().log(_classString, 'createListeners matches',
          myCustomObject: _matchesListener, exception: e, debugType: DebugType.error);
    }
  }

  Future<void> disposeListeners() async {
    MyLog().log(_classString, 'disposeListeners Building  ');
    try {
      await _usersListener?.cancel();
      await _matchesListener?.cancel();
      await _paramListener?.cancel();
    } catch (e) {
      MyLog().log(_classString, 'disposeListeners', exception: e, debugType: DebugType.error);
    }
  }

  void _downloadChangedUsers({
    required QuerySnapshot snapshot,
    required List<MyUser> addedUsers,
    required List<MyUser> modifiedUsers,
    required List<MyUser> removedUsers,
  }) {
    MyLog().log(_classString, '_downloadChangedUsers Number of users = ${snapshot.docs.length}');

    addedUsers.clear();
    modifiedUsers.clear();
    removedUsers.clear();

    for (var docChanged in snapshot.docChanges) {
      if (docChanged.doc.data() == null) {
        throw 'Error en la base de datos de usuarios';
      }

      Map<String, dynamic> data = docChanged.doc.data() as Map<String, dynamic>;

      MyUser user = MyUser();
      try {
        Date? lastLogin;
        if (data[strDB(DBFields.lastLogin)] != null) {
          lastLogin = Date(DateTime.parse(data[strDB(DBFields.lastLogin)]));
        }
        user = MyUser(
          name: data[strDB(DBFields.name)],
          email: data[strDB(DBFields.email)],
          userType: UserType.values[data[strDB(DBFields.userType)]],
          lastLogin: lastLogin,
          loginCount: data[strDB(DBFields.loginCount)] ?? 0,
          userId: docChanged.doc.id,
        );
      } catch (e) {
        MyLog().log(_classString, '_downloadChangedUsers formato incorrecto',
            myCustomObject: user, exception: e, debugType: DebugType.error);
      }
      if (user.hasNotEmptyFields()) {
        if (docChanged.type == DocumentChangeType.added) {
          addedUsers.add(user);
        } else if (docChanged.type == DocumentChangeType.modified) {
          modifiedUsers.add(user);
        } else if (docChanged.type == DocumentChangeType.removed) {
          removedUsers.add(user);
        }
      } else {
        MyLog().log(
            _classString, '_downloadChangedUsers Formato de usuario incorrecto en la Base de Datos',
            debugType: DebugType.error, myCustomObject: user);
      }
    }
  }

  void _downloadChangedMatches({
    required QuerySnapshot snapshot,
    required List<MyUser> Function() availableUsers,
    required List<MyMatch> addedMatches,
    required List<MyMatch> modifiedMatches,
    required List<MyMatch> removedMatches,
  }) {
    MyLog()
        .log(_classString, '_downloadChangedMatches Number of matches = ${snapshot.docs.length}');

    addedMatches.clear();
    modifiedMatches.clear();
    removedMatches.clear();

    for (var docChanged in snapshot.docChanges) {
      if (docChanged.doc.data() == null) {
        throw 'Error en la base de datos de partidos';
      }
      Map<String, dynamic> data = docChanged.doc.data() as Map<String, dynamic>;

      Date date = Date(DateTime.parse(docChanged.doc.id));
      MyMatch match = _createMatchFromMap(date: date, data: data, availableUsers: availableUsers);
      MyLog().log(_classString, '_downloadChangedMatches match = ', myCustomObject: match);

      if (docChanged.type == DocumentChangeType.added) {
        addedMatches.add(match);
      } else if (docChanged.type == DocumentChangeType.modified) {
        modifiedMatches.add(match);
      } else if (docChanged.type == DocumentChangeType.removed) {
        removedMatches.add(match);
      }
    }
  }

  Future<void> deleteOldData(DBFields collection, int daysAgo) async {
    MyLog().log(_classString, '_deleteOldData ${collection.name} $daysAgo');

    if (daysAgo <= 0) return;

    return _instance
        .collection(strDB(collection))
        .where(FieldPath.documentId,
            isLessThan: Date(DateTime.now()).subtract(Duration(days: daysAgo)).toYyyyMMdd())
        .get()
        .then((snapshot) {
      for (QueryDocumentSnapshot ds in snapshot.docs) {
        MyLog().log(_classString, 'Delete ${collection.name} ${ds.id}');
        ds.reference.delete();
      }
    }).catchError((onError) {
      MyLog().log(_classString, 'delete ${collection.name}',
          exception: onError, debugType: DebugType.error);
    });
  }

  MyMatch _createMatchFromMap({
    required Date date,
    required Map<String, dynamic> data,
    required List<MyUser> Function() availableUsers,
  }) {
    MyLog().log(_classString, '_createMatchFromMap $date ${data.length}', myCustomObject: data);

    MyMatch match = MyMatch(
      date: date,
      comment: data[strDB(DBFields.comment)] ?? '',
      isOpen: data[strDB(DBFields.isOpen)] ?? false,
    );

    match.courtNames.addAll((data[strDB(DBFields.courtNames)] ?? []).cast<String>());

    List<String> dbPlayersId = (data[strDB(DBFields.players)] ?? []).cast<String>();
    List<MyUser> matchPlayers = dbPlayersId
        .map((id) => availableUsers().firstWhereOrNull((user) => user.userId == id))
        .whereType<MyUser>()
        .toList();

    match.players.addAll(matchPlayers);

    if (matchPlayers.length != dbPlayersId.length) {
      MyLog().log(
          _classString,
          '_createMatchFromMap Match date ${match.date} \n players in DB=<<$dbPlayersId>>} '
          '\n users found = <<$matchPlayers>>}',
          debugType: DebugType.error);
    }

    return match;
  }
}
