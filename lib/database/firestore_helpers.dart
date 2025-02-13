import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:no_solo_padel_dev/interface/app_state.dart';

import '../models/debug.dart';
import '../models/register_model.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/date.dart';
import '../utilities/transformation.dart';
import 'fields.dart';

final String _classString = 'FsHelper'.toUpperCase();

/// Firestore helpers
class FsHelpers {
  final FirebaseFirestore _instance = FirebaseFirestore.instance;
  StreamSubscription? _usersListener;
  StreamSubscription? _paramListener;
  bool _usersDataLoaded = false;
  bool _parametersDataLoaded = false;
  final Completer<void> _dataLoadedCompleter = Completer<void>(); // completed after initial download

  FsHelpers() {
    MyLog.log(_classString, 'Building');
  }

  /// return false if existed, true if created
  Future<bool> createMatchIfNotExists({required Date matchId}) async {
    bool exists = await doesDocExist(collection: strDB(DBFields.matches), doc: matchId.toYyyyMMdd());
    if (exists) return false;
    MyLog.log(_classString, 'createMatchIfNotExists creating exist=$exists date=$matchId', level: Level.INFO);
    await updateMatch(match: MyMatch(id: matchId), updateCore: true, updatePlayers: true);
    return true;
  }

  Future<bool> doesDocExist({required String collection, required String doc}) async {
    return _instance.collection(collection).doc(doc).get().then((doc) => doc.exists);
  }

  /// create a subscription to a match
  /// matchFunction: checks if match has change and notify to listeners
  StreamSubscription? listenToMatch({
    required Date matchId,
    required AppState appState,
    required void Function(MyMatch match) matchFunction,
  }) {
    StreamSubscription? streamSubscription;
    MyLog.log(_classString, 'creating LISTENER for match=$matchId');
    try {
      streamSubscription =
          _instance.collection(strDB(DBFields.matches)).doc(matchId.toYyyyMMdd()).snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          MyMatch newMatch = MyMatch.fromJson(snapshot.data() as Map<String, dynamic>, appState);
          MyLog.log(_classString, 'LISTENER newMatch found = $newMatch', level: Level.INFO);
          matchFunction(newMatch);
        } else {
          MyLog.log(_classString, 'LISTENER Match data is null in Firestore.', level: Level.WARNING );
          matchFunction(MyMatch(id: matchId));
        }
      });
    } catch (e) {
      MyLog.log(_classString, 'createListeners ERROR listening to match $matchId', exception: e, level: Level.SEVERE);
    }

    return streamSubscription;
  }

  Future<void> createListeners({
    required void Function(MyParameters? parameters) parametersFunction,
    required void Function(List<MyUser> added, List<MyUser> modified, List<MyUser> removed) usersFunction,
  }) async {
    MyLog.log(_classString, 'Building createListeners ');
    assert(_paramListener == null);
    assert(_usersListener == null);

    // update parameters
    try {
      _paramListener = _instance
          .collection(strDB(DBFields.parameters))
          .doc(strDB(DBFields.parameters))
          .snapshots()
          .listen((snapshot) {
        MyLog.log(_classString, 'LISTENER parameters started');
        MyParameters? myParameters;
        if (snapshot.exists && snapshot.data() != null) {
          myParameters = MyParameters.fromJson(snapshot.data() as Map<String, dynamic>);
        }
        MyLog.log(_classString, 'LISTENER parameters = $myParameters', level: Level.INFO);
        parametersFunction(myParameters ?? MyParameters());
        _parametersDataLoaded = true;
        _checkDataLoaded();
      });
    } catch (e) {
      MyLog.log(_classString, 'createListeners parameters',
          myCustomObject: _paramListener, exception: e, level: Level.SEVERE);
    }

    // update users
    try {
      _usersListener = _instance.collection(strDB(DBFields.users)).snapshots().listen((snapshot) {
        MyLog.log(_classString, 'LISTENER users started');

        List<MyUser> addedUsers = [];
        List<MyUser> modifiedUsers = [];
        List<MyUser> removedUsers = [];
        _downloadChangedUsers(
          snapshot: snapshot,
          addedUsers: addedUsers,
          modifiedUsers: modifiedUsers,
          removedUsers: removedUsers,
        );
        MyLog.log(_classString,
            'LISTENER users added=${addedUsers.length} mod=${modifiedUsers.length} removed=${removedUsers.length}',
            level: Level.INFO);
        usersFunction(addedUsers, modifiedUsers, removedUsers);
        _usersDataLoaded = true;
        _checkDataLoaded();
      });
    } catch (e) {
      MyLog.log(_classString, 'createListeners users',
          myCustomObject: _usersListener, exception: e, level: Level.SEVERE);
    }
  }

  void _checkDataLoaded() {
    if (_usersDataLoaded && _parametersDataLoaded && !_dataLoadedCompleter.isCompleted) {
      MyLog.log(_classString, '_checkDataLoaded Completer completed...  ', level: Level.INFO);
      _dataLoadedCompleter.complete();
    }
  }

  Future<void> get dataLoaded {
    MyLog.log(_classString, 'dataLoaded waiting to complete the Completer...  ', level: Level.INFO);
    return _dataLoadedCompleter.future;
  }

  Future<void> disposeListeners() async {
    MyLog.log(_classString, 'disposeListeners Building  ');
    try {
      await _usersListener?.cancel();
      await _paramListener?.cancel();
    } catch (e) {
      MyLog.log(_classString, 'disposeListeners', exception: e, level: Level.SEVERE);
    }
  }

  void _downloadChangedUsers({
    required QuerySnapshot snapshot,
    required List<MyUser> addedUsers,
    required List<MyUser> modifiedUsers,
    required List<MyUser> removedUsers,
  }) {
    MyLog.log(_classString, '_downloadChangedUsers #users = ${snapshot.docs.length}', level: Level.INFO);

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
          MyLog.log(_classString, '_downloadChangedUsers Empty user!!!', level: Level.SEVERE, myCustomObject: user);
        }
      } catch (e) {
        MyLog.log(_classString, '_downloadUsers Wrong Format', myCustomObject: data, exception: e, level: Level.SEVERE);
      }
    }
  }

  Future<void> deleteOldData(DBFields collection, int daysAgo) async {
    MyLog.log(_classString, '_deleteOldData collection=${collection.name} days=$daysAgo', level: Level.INFO);

    if (daysAgo <= 0) return;

    return _instance
        .collection(strDB(collection))
        .where(FieldPath.documentId, isLessThan: Date(DateTime.now()).subtract(Duration(days: daysAgo)).toYyyyMMdd())
        .get()
        .then((snapshot) {
      for (QueryDocumentSnapshot ds in snapshot.docs) {
        MyLog.log(_classString, 'Delete collection=${collection.name} id=${ds.id}', level: Level.INFO);
        ds.reference.delete();
      }
    }).catchError((onError) {
      MyLog.log(_classString, 'Delete collection=${collection.name}', exception: onError, level: Level.SEVERE);
    });
  }

  Stream<List<T>>? _getStream<T>({
    required String collection,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(Map<String, dynamic>, AppState)? fromJsonWithState,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
    AppState? appState,
  }) {
    MyLog.log(_classString, '_getStream collection=$collection', level: Level.INFO);
    Query query = _instance.collection(collection);

    // Order by documentId FIRST
    query = query.orderBy(FieldPath.documentId); // Add this line FIRST

    if (fromDate != null) {
      query = query.where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMMdd());
    }
    if (maxDate != null) {
      query = query.where(FieldPath.documentId, isLessThan: maxDate.toYyyyMMdd());
    }

    try {
      if (fromJson != null) {
        return query.snapshots().transform(transformer(fromJson));
      } else if (fromJsonWithState != null && appState != null) {
        return query.snapshots().transform(transformerWithState(fromJsonWithState, appState));
      } else {
        throw ArgumentError("Error transforming matches");
      }
    } catch (e) {
      MyLog.log(_classString, '_getStream collection=$collection', exception: e, level: Level.SEVERE);
      return null;
    }
  }

  Stream<List<T>>? getStreamNoState<T>({
    required String collection,
    required T Function(Map<String, dynamic>) fromJson,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
  }) {
    MyLog.log(_classString, 'getStream collection=$collection', level: Level.INFO);
    return _getStream(collection: collection, fromJson: fromJson, fromDate: fromDate, maxDate: maxDate);
  }

  Stream<List<T>>? getStreamWithState<T>({
    required String collection,
    required T Function(Map<String, dynamic>, AppState) fromJsonWithState,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
    required AppState appState,
  }) {
    MyLog.log(_classString, 'getStream collection=$collection', level: Level.INFO);
    return _getStream(
        collection: collection,
        fromJsonWithState: fromJsonWithState,
        fromDate: fromDate,
        maxDate: maxDate,
        appState: appState);
  }

  // stream of messages registered
  Stream<List<RegisterModel>>? getRegisterStream(int fromDaysAgo) => getStreamNoState(
        collection: strDB(DBFields.register),
        fromJson: RegisterModel.fromJson,
        fromDate: Date.now().subtract(Duration(days: fromDaysAgo)),
      );

  // stream of users
  Stream<List<MyUser>>? getUsersStream() => getStreamNoState(
        collection: strDB(DBFields.users),
        fromJson: MyUser.fromJson,
      );

  // stream of matches
  Stream<List<MyMatch>>? getMatchesStream({required AppState appState, Date? fromDate, Date? maxDate}) =>
      getStreamWithState(
        collection: strDB(DBFields.matches),
        fromJsonWithState: MyMatch.fromJson,
        fromDate: fromDate,
        maxDate: maxDate,
        appState: appState,
      );

  Future<T?> getObjectWithState<T>({
    required String collection,
    required String doc,
    required T Function(Map<String, dynamic>, AppState) fromJson,
    required AppState appState,
  }) async =>
      _getObject(collection: collection, doc: doc, fromJsonAppState: fromJson, appState: appState);

  Future<T?> getObjectNoState<T>({
    required String collection,
    required String doc,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async =>
      _getObject(collection: collection, doc: doc, fromJson: fromJson);

  Future<T?> _getObject<T>({
    required String collection,
    required String doc,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(Map<String, dynamic> json, AppState appState)? fromJsonAppState,
    AppState? appState,
  }) async {
    MyLog.log(_classString, 'getObject $collection $doc');

    try {
      DocumentSnapshot documentSnapshot = await _instance.collection(collection).doc(doc).get();

      Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null && data.isNotEmpty) {
        T item;
        if (appState == null && fromJson != null) {
          item = fromJson(data);
        } else if (appState != null && fromJsonAppState != null) {
          item = fromJsonAppState(data, appState);
        } else {
          throw ArgumentError("Argument error for _getObject.");
        }

        return item;
      } else {
        MyLog.log(_classString, 'getObject $collection $doc not found or empty', level: Level.SEVERE);
      }
    } catch (e) {
      MyLog.log(_classString, 'getObject ', exception: e, level: Level.SEVERE);
    }
    return null;
  }

  Future<MyUser?> getUser(String userId) async =>
      getObjectNoState(collection: strDB(DBFields.users), doc: userId, fromJson: MyUser.fromJson);

  Future<MyMatch?> getMatch(String matchId, AppState appState) async => getObjectWithState(
      collection: strDB(DBFields.matches), doc: matchId, fromJson: MyMatch.fromJson, appState: appState);

  Future<MyParameters> getParameters() async =>
      await getObjectNoState(
          collection: strDB(DBFields.parameters), doc: strDB(DBFields.parameters), fromJson: MyParameters.fromJson) ??
      MyParameters();

  // TODO: not used
  Future<MyUser?> getUserByEmail(String email) async {
    MyLog.log(_classString, 'getUserByEmail $email', level: Level.INFO);

    try {
      QuerySnapshot querySnapshot =
          await _instance.collection(strDB(DBFields.users)).where('email', isEqualTo: email).get();

      if (querySnapshot.size > 1) {
        MyLog.log(_classString, 'getUserByEmail $email number = ${querySnapshot.size}', level: Level.SEVERE);
        return null;
      }
      if (querySnapshot.size == 0) {
        MyLog.log(_classString, 'getUserByEmail $email doesn\'t exist', level: Level.INFO);
        return null;
      }

      Map<String, dynamic>? data = querySnapshot.docs.first.data() as Map<String, dynamic>?;
      if (data != null && data.isNotEmpty) {
        return MyUser.fromJson(data);
      } else {
        MyLog.log(_classString, 'getUserByEmail $email not found or empty', level: Level.SEVERE);
      }
    } catch (e) {
      MyLog.log(_classString, 'getUserByEmail ', exception: e, level: Level.SEVERE);
      return null;
    }
    return null;
  }

  Future<List<T>> _getAllObjects<T>({
    required String collection,
    T Function(Map<String, dynamic>, AppState appState)? fromJsonAppState,
    T Function(Map<String, dynamic>)? fromJson,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
    AppState? appState,
  }) async {
    MyLog.log(_classString, '_getAllObjects');

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
        T item;
        if (appState == null && fromJson != null) {
          item = fromJson(data);
        } else if (appState != null && fromJsonAppState != null) {
          item = fromJsonAppState(data, appState);
        } else {
          throw ArgumentError("Argument error for _getAllObjects.");
        }

        MyLog.log(_classString, '_getAllObjects $collection = $item');
        items.add(item);
      }
    } catch (e) {
      MyLog.log(_classString, '_getAllObjects', exception: e, level: Level.SEVERE);
    }
    MyLog.log(_classString, '_getAllObjects #$collection = ${items.length} ', level: Level.INFO);
    return items;
  }

  /// Retrieves a list of objects from the specified Firestore collection.
  ///
  /// This function should be used when the [fromJson] function *does not* require
  /// an [AppState] instance.
  Future<List<T>> getAllObjectsNoAppState<T>({
    required String collection,
    required T Function(Map<String, dynamic>) fromJson,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
  }) async =>
      _getAllObjects(collection: collection, fromJson: fromJson, fromDate: fromDate, maxDate: maxDate);

  /// Retrieves a list of objects from the specified Firestore collection.
  ///
  /// This function should be used when the [fromJson] function *requires*
  /// an [AppState] instance.
  Future<List<T>> getAllObjectsAppState<T>({
    required String collection,
    required T Function(Map<String, dynamic>, AppState) fromJson,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
    required AppState appState,
  }) async =>
      _getAllObjects(
          collection: collection, fromJsonAppState: fromJson, fromDate: fromDate, maxDate: maxDate, appState: appState);

  Future<List<MyUser>> getAllUsers() async => getAllObjectsNoAppState<MyUser>(
        collection: strDB(DBFields.users),
        fromJson: MyUser.fromJson,
      );

  Future<List<MyMatch>> getAllMatches({
    required AppState appState,
    Date? fromDate,
    Date? maxDate,
  }) async =>
      getAllObjectsAppState(
        collection: strDB(DBFields.matches),
        fromJson: MyMatch.fromJson,
        fromDate: fromDate,
        maxDate: maxDate,
        appState: appState,
      );

  Future<void> updateObject({
    required Map<String, dynamic> map,
    required String collection,
    required String doc,
    bool forceSet = false, // replaces the old object if exists
  }) async {
    MyLog.log(_classString, 'updateObject  $collection $doc', level: Level.INFO);
    if (forceSet) {
      return _instance.collection(collection).doc(doc).set(map).catchError((onError) {
        MyLog.log(_classString, 'updateObject ERROR setting:', exception: onError, level: Level.SEVERE);
      });
    } else {
      return _instance.collection(collection).doc(doc).update(map).catchError((onError) {
        MyLog.log(_classString, 'updateObject ERROR updating:', exception: onError, level: Level.WARNING);
        MyLog.log(_classString, 'updateObject creating:', level: Level.INFO);
        _instance.collection(collection).doc(doc).set(map);
      }).catchError((onError) {
        MyLog.log(_classString, 'updateObject ERROR:', exception: onError, level: Level.SEVERE);
      });
    }
  }

  Future<void> updateUser(MyUser myUser) async {
    if (myUser.id == '') {
      MyLog.log(_classString, 'updateUser ', myCustomObject: myUser, level: Level.SEVERE);
    }
    return updateObject(
      map: myUser.toJson(),
      collection: strDB(DBFields.users),
      doc: myUser.id,
      forceSet: false, // replaces the old object if exists
    );
  }

  /// core = comment + isOpen + courtNames (all except players)
  Future<void> updateMatch({required MyMatch match, required bool updateCore, required bool updatePlayers}) async =>
      updateObject(
        map: match.toJson(core: updateCore, matchPlayers: updatePlayers),
        collection: strDB(DBFields.matches),
        doc: match.id.toYyyyMMdd(),
        forceSet: false, // replaces the old object if exists
      );

  Future<void> updateRegister(RegisterModel registerModel) async => updateObject(
        map: registerModel.toJson(),
        collection: strDB(DBFields.register),
        doc: registerModel.date.toYyyyMMdd(),
        forceSet: false, // replaces the old object if exists
      );

  Future<void> updateParameters(MyParameters myParameters) async => updateObject(
        map: myParameters.toJson(),
        collection: strDB(DBFields.parameters),
        doc: strDB(DBFields.parameters),
        forceSet: true,
      );

  Future<void> deleteUser(MyUser myUser) async {
    MyLog.log(_classString, 'deleteUser deleting user $myUser');
    if (myUser.id == '') {
      MyLog.log(_classString, 'deleteUser wrong id', myCustomObject: myUser, level: Level.SEVERE);
    }

    // delete user
    try {
      MyLog.log(_classString, 'deleteUser user $myUser deleted');
      await _instance.collection(strDB(DBFields.users)).doc(myUser.id).delete();
    } catch (e) {
      MyLog.log(_classString, 'deleteUser error when deleting', myCustomObject: myUser, level: Level.SEVERE);
    }
  }

  /// return match if user was inserted. null otherwise
  Future<MyMatch?> addPlayerToMatch({
    required Date matchId,
    required MyUser player,
    required AppState appState,
    int position = -1,
  }) async {
    MyLog.log(_classString, 'addPlayer adding user $player to $matchId position $position');
    DocumentReference documentReference = _instance.collection(strDB(DBFields.matches)).doc(matchId.toYyyyMMdd());

    return _instance.runTransaction((transaction) async {
      // get snapshot
      DocumentSnapshot snapshot = await transaction.get(documentReference);
      if (!snapshot.exists) {
        throw Exception('No existe el partido asociado a la fecha $matchId');
      }

      // get match
      MyMatch myMatch = MyMatch.fromJson(snapshot.data() as Map<String, dynamic>, appState);
      MyLog.log(_classString, 'addPlayer match = ', myCustomObject: myMatch);

      // add player in memory match
      int posInserted = myMatch.insertPlayer(player, position: position);
      if (posInserted == -1) return null;
      MyLog.log(_classString, 'addPlayer inserted match = ', myCustomObject: myMatch);

      // add match to firebase
      transaction.update(documentReference, myMatch.toJson(core: false, matchPlayers: true));
      return myMatch;
    }).catchError((onError) {
      MyLog.log(_classString, 'addPlayer error adding $player to match $matchId', level: Level.SEVERE);
      throw Exception('Error al añadir jugador $player al partido $matchId\n'
          'Error = $onError');
    });
  }

  /// return match if user was deleted. null otherwise
  Future<MyMatch?> deletePlayerFromMatch({
    required Date matchId,
    required MyUser user,
    required AppState appState,
  }) async {
    MyLog.log(_classString, 'deletePlayerFromMatch deleting user $user from $matchId');
    DocumentReference documentReference = _instance.collection(strDB(DBFields.matches)).doc(matchId.toYyyyMMdd());

    return _instance.runTransaction((transaction) async {
      // get match
      DocumentSnapshot snapshot = await transaction.get(documentReference);
      if (!snapshot.exists) {
        throw Exception('No existe el partido asociado a la fecha $matchId');
      }

      // get match
      MyMatch myMatch = MyMatch.fromJson(snapshot.data() as Map<String, dynamic>, appState);
      MyLog.log(_classString, 'deletePlayerFromMatch match = ', myCustomObject: myMatch);

      // delete player in match
      bool removed = myMatch.removePlayer(user);
      if (!removed) return null;
      MyLog.log(_classString, 'deletePlayerFromMatch removed match = ', myCustomObject: myMatch);

      // add match to firebase
      transaction.update(documentReference, myMatch.toJson(core: false, matchPlayers: true));
      return myMatch;
    }).catchError((onError) {
      MyLog.log(_classString, 'deletePlayerFromMatch error deleting $user from match $matchId', level: Level.SEVERE);
      throw Exception('Error al eliminar el jugador $user del partido $matchId\n'
          'Error = $onError');
    });
  }
}
