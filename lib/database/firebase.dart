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

  // return false if existed, true if created
  Future<bool> createMatchIfNotExists({required MyMatch match}) async {
    bool exists =
        await doesDocExist(collection: strDB(DBFields.matches), doc: match.date.toYyyyMMdd());
    MyLog().log(_classString, 'createMatchIfNotExists exists $exists $match');
    if (exists) return false;
    await updateMatch(match: match, updateCore: true, updatePlayers: true);
    return true;
  }

  Future<bool> doesDocExist({required String collection, required String doc}) async {
    return _instance.collection(collection).doc(doc).get().then((doc) => doc.exists);
  }


  // TODO: follow from here
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
          MyLog().log(_classString,
              '_downloadChangedUsers Formato de usuario incorrecto en la Base de Datos',
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

  Stream<List<T>>? getStream<T>({
    required String collection,
    required T Function(Map<String, dynamic> json) fromJson,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
  }) {
    MyLog().log(_classString, 'getStream $collection');
    Query query = _instance.collection(collection);
    if (fromDate != null) {
      query = query.where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMMdd());
    }
    if (maxDate != null) {
      query = query.where(FieldPath.documentId, isLessThan: maxDate.toYyyyMMdd());
    }
    try {
      return query.snapshots().transform(transformer(fromJson));
    } catch (e) {
      MyLog().log(_classString, 'getStream $collection', exception: e, debugType: DebugType.error);
      return null;
    }
  }

  // stream of messages registered
  Stream<List<RegisterModel>>? getRegisterStream(int fromDaysAgo) => getStream(
        collection: strDB(DBFields.register),
        fromJson: RegisterModel.fromJson,
        fromDate: Date.now().subtract(Duration(days: fromDaysAgo)),
      );

  // stream of users
  Stream<List<MyUser>>? getUsersStream() => getStream(
        collection: strDB(DBFields.users),
        fromJson: MyUser.fromJson,
      );

  // stream of matches
  Stream<List<MyMatch>>? getMatchesStream({required Date fromDate, required int numDays}) =>
      getStream(
        collection: strDB(DBFields.matches),
        fromJson: MyMatch.fromJson,
        fromDate: fromDate,
        maxDate: Date.now().add(Duration(days: numDays)),
      );

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

  Future<List<T>> getAllObjects<T>({
    required String collection,
    required T Function(Map<String, dynamic> json) fromJson,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
  }) async {
    MyLog().log(_classString, 'gelAllObjects');
    List<T> items = [];
    Query query = _instance.collection(collection);
    if (fromDate != null) {
      query = query.where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMMdd());
    }
    if (maxDate != null) {
      query = query.where(FieldPath.documentId, isLessThan: maxDate.toYyyyMMdd());
    }

    try {
      QuerySnapshot querySnapshot = await query.get();
      for (var doc in querySnapshot.docs) {
        if (doc.data() == null) throw 'Error en la base de datos $collection';
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        T item = fromJson(data);
        MyLog().log(_classString, 'gelAllObjects $collection = ', myCustomObject: item);
        items.add(item);
      }
    } catch (e) {
      MyLog().log(_classString, 'gelAllObjects', exception: e, debugType: DebugType.error);
    }

    return items;
  }

  Future<List<MyUser>> getAllUsers() async => getAllObjects(
        collection: strDB(DBFields.users),
        fromJson: MyUser.fromJson,
      );

  Future<List<MyMatch>> getAllMatches({
    required Date fromDate,
    required int numDays,
  }) async =>
      getAllObjects(
        collection: strDB(DBFields.matches),
        fromJson: MyMatch.fromJson,
        fromDate: fromDate,
        maxDate: Date.now().add(Duration(days: numDays)),
      );

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

  // core = comment + isOpen + courtNAmes (all except players)
  Future<void> updateMatch(
          {required MyMatch match, required bool updateCore, required bool updatePlayers}) async =>
      updateObject(
        map: match.toJson(core: updateCore, matchPlayers: updatePlayers),
        collection: strDB(DBFields.matches),
        doc: match.date.toYyyyMMdd(),
        forceSet: false,
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
