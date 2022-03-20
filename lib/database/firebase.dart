import 'dart:async';

import 'package:collection/collection.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/debug.dart';
import '../models/register_model.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/date.dart';
import '../utilities/transformation.dart';
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

  // core = comment + isOpen + courtNAmes (all except players)
  Future<void> uploadMatch(
      {required MyMatch match, required bool updateCore, required bool updatePlayers}) async {
    MyLog().log(_classString, 'uploadMatch $match');

    Map<String, dynamic> uploadMap = {
      strDB(DBFields.date): match.date.toYyyyMMdd(),
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

  Future<bool> doesDocExist({required String collection, required String doc}) async {
    return _instance.collection(collection).doc(doc).get().then((doc) => doc.exists);
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

      try {
        MyUser user = MyUser.fromJson(data);

        if (user.hasNotEmptyFields()) {
          users.add(user);
        } else {
          MyLog().log(
              _classString, '_downloadUsers Formato de usuario incorrecto en la Base de Datos',
              debugType: DebugType.error, myCustomObject: user);
        }

      } catch (e) {
        MyLog().log(_classString, '_downloadUsers formato incorrecto',
            myCustomObject: data, exception: e, debugType: DebugType.error);
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
    try {
      _paramListener = _instance
          .collection(strDB(DBFields.parameters))
          .doc(strDB(DBFields.parameters))
          .snapshots()
          .listen((snapshot) {
        MyLog().log(_classString, 'LISTENER parameters started');
        MyParameters? myParameters;
        if (snapshot.data() != null) {
          myParameters = MyParameters.fromJson(snapshot.data() as Map<String, dynamic>);
        }
        MyLog().log(_classString, 'LISTENER parameters = $myParameters');
        parametersFunction(myParameters ?? MyParameters());
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
      try {
        MyUser user = MyUser.fromJson(data);

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
      } catch (e) {
        MyLog().log(_classString, '_downloadUsers formato incorrecto',
            myCustomObject: data, exception: e, debugType: DebugType.error);
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

  /// ----------------------------------------------------------------------------

  // stream of messages registered
  Stream<List<RegisterModel>>? getRegisterStream(int fromDaysAgo) {
    MyLog().log(_classString, 'getRegisterStream');
    try {
      return _instance
          .collection(strDB(DBFields.register))
          .where(FieldPath.documentId,
              isGreaterThan: Date.now().subtract(Duration(days: fromDaysAgo)).toYyyyMMdd())
          .snapshots()
          .transform(transformer(RegisterModel.fromJson));
    } catch (e) {
      MyLog().log(_classString, 'getRegisterStream', exception: e, debugType: DebugType.error);
      return null;
    }
  }

  // stream of users
  Stream<List<MyUser>>? getUsersStream() {
    MyLog().log(_classString, 'getUsersStream');
    try {
      return _instance
          .collection(strDB(DBFields.users))
          .snapshots()
          .transform(transformer(MyUser.fromJson));
    } catch (e) {
      MyLog().log(_classString, 'getUsersStream', exception: e, debugType: DebugType.error);
      return null;
    }
  }

  // stream of matches
  Stream<List<MyMatch>>? getMatchesStream({required Date fromDate, required int numDays}) {
    MyLog().log(_classString, 'getMatchesStream');
    try {
      return _instance
          .collection(strDB(DBFields.matches))
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMMdd())
          .where(FieldPath.documentId,
              isLessThan: Date.now().add(Duration(days: numDays)).toYyyyMMdd())
          .snapshots()
          .transform(transformer(MyMatch.fromJson));
    } catch (e) {
      MyLog().log(_classString, 'getMatchesStream', exception: e, debugType: DebugType.error);
      return null;
    }
  }

  Future<T?> getObject<T>({
    required String collection,
    required String doc,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    MyLog().log(_classString, 'getObject $collection $doc');

    try {
      DocumentSnapshot documentSnapshot = await _instance.collection(collection).doc(doc).get();

      Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null && data.isNotEmpty) {
        return fromJson(data);
      } else {
        MyLog().log(_classString, 'getObject $collection $doc not found or empty');
      }
    } catch (e) {
      MyLog().log(_classString, 'getObject ', exception: e, debugType: DebugType.error);
      return null;
    }
    return null;
  }

  Future<MyUser?> getUser(String userId) async =>
      getObject(collection: strDB(DBFields.users), doc: userId, fromJson: MyUser.fromJson);

  Future<MyMatch?> getMatch(String date) async =>
      getObject(collection: strDB(DBFields.matches), doc: date, fromJson: MyMatch.fromJson);

  Future<MyParameters> getParameters() async =>
      await getObject(
          collection: strDB(DBFields.parameters),
          doc: strDB(DBFields.parameters),
          fromJson: MyParameters.fromJson) ??
      MyParameters();

  Future<void> updateObject({
    required Map<String, dynamic> map,
    required String collection,
    required String doc,
    bool forceSet = false,
  }) async {
    MyLog().log(_classString, 'updateObject  $collection $doc $map');
    if (forceSet) {
      return _instance.collection(collection).doc(doc).set(map).catchError((onError) {
        MyLog().log(_classString, 'updateObject ', exception: onError, debugType: DebugType.error);
      });
    } else {
      return _instance.collection(collection).doc(doc).update(map).catchError((onError) {
        _instance.collection(collection).doc(doc).set(map);
      }).catchError((onError) {
        MyLog().log(_classString, 'updateObject ', exception: onError, debugType: DebugType.error);
      });
    }
  }

  Future<void> updateUser(MyUser myUser) async => updateObject(
        map: myUser.toJson(),
        collection: strDB(DBFields.users),
        doc: myUser.userId,
        forceSet: true,
      );

  Future<void> updateRegister(RegisterModel registerModel) async => updateObject(
        map: registerModel.toJson(),
        collection: strDB(DBFields.register),
        doc: registerModel.date.toYyyyMMdd(),
        forceSet: false,
      );

  Future<void> updateParameters(MyParameters myParameters) async => updateObject(
        map: myParameters.toJson(),
        collection: strDB(DBFields.parameters),
        doc: strDB(DBFields.parameters),
        forceSet: true,
      );
}
