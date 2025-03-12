import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../interface/app_state.dart';
import '../models/debug.dart';
import '../models/register_model.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/date.dart';
import '../utilities/transformation.dart';
import 'fields.dart';

final String _classString = '<db> FsHelper'.toLowerCase();

/// Firestore helpers
class FsHelpers {
  final FirebaseFirestore _instance = FirebaseFirestore.instance;
  StreamSubscription? _usersListener;
  StreamSubscription? _paramListener;
  bool _usersDataLoaded = false;
  bool _parametersDataLoaded = false;
  final Completer<void> _dataLoadedCompleter = Completer<void>(); // completed after initial download

  FsHelpers() {
    MyLog.log(_classString, 'Constructor');
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
    MyLog.log(_classString, 'listenToMatch creating LISTENER for match=$matchId');
    StreamSubscription? streamSubscription;
    try {
      streamSubscription =
          _instance.collection(strDB(DBFields.matches)).doc(matchId.toYyyyMMdd()).snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          MyMatch newMatch = MyMatch.fromJson(snapshot.data() as Map<String, dynamic>, appState);
          MyLog.log(_classString, 'listenToMatch LISTENER newMatch found = $newMatch', level: Level.INFO, indent: true);
          matchFunction(newMatch);
        } else {
          MyLog.log(_classString, 'listenToMatch LISTENER Match data is null in Firestore.',
              level: Level.WARNING, indent: true);
          matchFunction(MyMatch(id: matchId));
        }
      });
    } catch (e) {
      MyLog.log(_classString, 'listenToMatch ERROR listening to match $matchId',
          exception: e, level: Level.SEVERE, indent: true);
    }

    return streamSubscription;
  }

  Future<void> createListeners({
    required void Function(MyParameters? parameters) parametersFunction,
    required void Function(List<MyUser> added, List<MyUser> modified, List<MyUser> removed) usersFunction,
  }) async {
    MyLog.log(_classString, 'createListeners ');
    assert(_paramListener == null);
    assert(_usersListener == null);

    // update parameters
    try {
      MyLog.log(_classString, 'creating LISTENER for parameters ', indent: true );
      _paramListener = _instance
          .collection(strDB(DBFields.parameters))
          .doc(strDB(DBFields.parameters))
          .snapshots()
          .listen((snapshot) {
        MyLog.log(_classString, 'createListeners LISTENER loading parameters into appState ...', indent: true);
        MyParameters? myParameters;
        if (snapshot.exists && snapshot.data() != null) {
          myParameters = MyParameters.fromJson(snapshot.data() as Map<String, dynamic>);
        }
        MyLog.log(_classString, 'createListeners LISTENER parameters to load = $myParameters',
            level: Level.INFO, indent: true);
        parametersFunction(myParameters ?? MyParameters());
        _parametersDataLoaded = true;
        _checkDataLoaded();
      });
    } catch (e) {
      MyLog.log(_classString, 'createListeners parameters',
          myCustomObject: _paramListener, exception: e, level: Level.SEVERE, indent: true);
    }

    // update users
    try {
      MyLog.log(_classString, 'creating LISTENER for users ', indent: true );
      _usersListener = _instance.collection(strDB(DBFields.users)).snapshots().listen((snapshot) {
        MyLog.log(_classString, 'createListeners LISTENER loading users into appState', indent: true);

        List<MyUser> addedUsers = [];
        List<MyUser> modifiedUsers = [];
        List<MyUser> removedUsers = [];
        _downloadChangedUsers(
          snapshot: snapshot,
          addedUsers: addedUsers,
          modifiedUsers: modifiedUsers,
          removedUsers: removedUsers,
        );
        MyLog.log(
            _classString,
            'createListeners LISTENER users added=${addedUsers.length} mod=${modifiedUsers.length} '
            'removed=${removedUsers.length}',
            level: Level.INFO,
            indent: true);
        usersFunction(addedUsers, modifiedUsers, removedUsers);
        _usersDataLoaded = true;
        _checkDataLoaded();
      });
    } catch (e) {
      MyLog.log(_classString, 'createListeners createListeners Error loading users',
          myCustomObject: _usersListener, exception: e, level: Level.SEVERE, indent: true);
    }
  }

  void _checkDataLoaded() {
    if (_usersDataLoaded && _parametersDataLoaded && !_dataLoadedCompleter.isCompleted) {
      MyLog.log(_classString, '_checkDataLoaded Loading Completer completed...  ', level: Level.INFO);
      _dataLoadedCompleter.complete();
    }
  }

  /// completed when the completer _dataLoadedCompleter is complete
  Future<void> get dataLoaded {
    MyLog.log(_classString, 'dataLoaded: loading data. Waiting to finish...  ', level: Level.INFO);
    return _dataLoadedCompleter.future;
  }

  Future<void> disposeListeners() async {
    MyLog.log(_classString, 'disposeListeners');
    try {
      await _usersListener?.cancel();
      await _paramListener?.cancel();
    } catch (e) {
      MyLog.log(_classString, 'disposeListeners', exception: e, level: Level.SEVERE, indent: true);
    }
  }

  void _downloadChangedUsers({
    required QuerySnapshot snapshot,
    required List<MyUser> addedUsers,
    required List<MyUser> modifiedUsers,
    required List<MyUser> removedUsers,
  }) {
    MyLog.log(_classString, '_downloadChangedUsers update #users = ${snapshot.docs.length}', level: Level.INFO);

    addedUsers.clear();
    modifiedUsers.clear();
    removedUsers.clear();

    for (var docChanged in snapshot.docChanges) {
      if (docChanged.doc.data() == null) {
        MyLog.log(_classString, '_downloadChangedUsers ERROR data null', level: Level.SEVERE, indent: true);
        throw 'Error en la base de datos de usuarios';
      }

      Map<String, dynamic> data = docChanged.doc.data() as Map<String, dynamic>;
      try {
        MyUser user = MyUser.fromJson(data);
        MyLog.log(_classString, '_downloadChangedUsers user=$user', indent: true);

        if (user.hasNotEmptyFields()) {
          if (docChanged.type == DocumentChangeType.added) {
            addedUsers.add(user);
          } else if (docChanged.type == DocumentChangeType.modified) {
            modifiedUsers.add(user);
          } else if (docChanged.type == DocumentChangeType.removed) {
            removedUsers.add(user);
          }
        } else {
          MyLog.log(_classString, '_downloadChangedUsers Error: Empty user!!!',
              level: Level.SEVERE, myCustomObject: user, indent: true);
        }
      } catch (e) {
        MyLog.log(_classString, '_downloadUsers Error: Wrong Format',
            myCustomObject: data, exception: e, level: Level.SEVERE, indent: true);
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
        MyLog.log(_classString, 'deleteOldData Delete collection=${collection.name} id=${ds.id}',
            level: Level.INFO, indent: true);
        ds.reference.delete();
      }
    }).catchError((onError) {
      MyLog.log(_classString, 'deleteOldData Delete collection=${collection.name}',
          exception: onError, level: Level.SEVERE, indent: true);
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
      MyLog.log(_classString, '_getStream ERROR collection=$collection',
          exception: e, level: Level.SEVERE, indent: true);
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
        MyLog.log(_classString, 'getObject $collection $doc not found or empty', level: Level.SEVERE, indent: true);
      }
    } catch (e) {
      MyLog.log(_classString, 'getObject ', exception: e, level: Level.SEVERE, indent: true);
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

  /// Retrieves a user from Firestore based on their email address.
  /// Not used in the project
  ///
  /// This function queries the 'users' collection for a document where the 'email'
  /// field matches the provided [email].
  ///
  /// If a single matching user is found, it returns a `MyUser` object created from
  /// the document's data.
  ///
  /// If no users are found or if multiple users with the same email exist, it
  /// returns `null`.
  ///
  /// Logs information and errors using the `MyLog` service.
  ///
  /// Parameters:
  ///   - [email]: The email address of the user to retrieve.
  ///
  /// Returns:
  ///   - A `Future` that resolves to a `MyUser` object if a single user is found,
  ///     or `null` if no user is found or if an error occurs.
  ///
  /// Logs:
  ///   - INFO: Logs the start of the retrieval process and when a user is not found.
  ///   - SEVERE: Logs errors, multiple users with the same email, or when the
  ///             retrieved document's data is empty or null.
  ///
  /// Throws:
  ///   - Catches and logs any exceptions that occur during the Firestore query.
  Future<MyUser?> getUserByEmail(String email) async {
    MyLog.log(_classString, 'getUserByEmail $email', level: Level.INFO);

    try {
      QuerySnapshot querySnapshot =
          await _instance.collection(strDB(DBFields.users)).where('email', isEqualTo: email).get();

      if (querySnapshot.size > 1) {
        MyLog.log(_classString, 'getUserByEmail $email incorrect number = ${querySnapshot.size}', level: Level.SEVERE);
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
    Query Function(Query)? filter, // Optional filter function
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

    if (filter != null) {
      query = filter(query);
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

        MyLog.log(_classString, '_getAllObjects $collection = $item', indent: true);
        items.add(item);
      }
    } catch (e) {
      MyLog.log(_classString, '_getAllObjects', exception: e, level: Level.SEVERE, indent: true);
    }
    MyLog.log(_classString, '_getAllObjects #$collection = ${items.length} ', level: Level.INFO, indent: true);
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
    required AppState appState,
    Date? fromDate, // FieldPath.documentId >= fromDate.toYyyyMMdd()
    Date? maxDate, // FieldPath.documentId < maxDate.toYyyyMMdd()
    Query Function(Query)? filter, // Optional filter function
  }) async =>
      _getAllObjects(
        collection: collection,
        fromJsonAppState: fromJson,
        fromDate: fromDate,
        maxDate: maxDate,
        appState: appState,
        filter: filter,
      );

  Future<List<MyUser>> getAllUsers() async => getAllObjectsNoAppState<MyUser>(
        collection: strDB(DBFields.users),
        fromJson: MyUser.fromJson,
      );

  /// returns all matches containing a player
  Future<List<MyMatch>> getAllPlayerMatches({
    required AppState appState,
    required String playerId,
    Date? fromDate,
    Date? maxDate,
  }) async {
    return getAllObjectsAppState(
      collection: strDB(DBFields.matches),
      fromJson: MyMatch.fromJson,
      fromDate: fromDate,
      maxDate: maxDate,
      appState: appState,
      filter: (query) => query.where(strDB(DBFields.players), arrayContains: playerId),
    );

    // query = query.where('players', arrayContains: playerId);
  }

  Future<void> updateObject({
    required Map<String, dynamic> map,
    required String collection,
    required String doc,
    bool forceSet = false, // replaces the old object if exists
  }) async {
    MyLog.log(_classString, 'updateObject  $collection $doc', level: Level.INFO);
    if (forceSet) {
      return _instance.collection(collection).doc(doc).set(map).catchError((onError) {
        MyLog.log(_classString, 'updateObject ERROR setting:', exception: onError, level: Level.SEVERE, indent: true);
      });
    } else {
      return _instance.collection(collection).doc(doc).update(map).catchError((onError) {
        MyLog.log(_classString, 'updateObject ERROR updating:', exception: onError, level: Level.WARNING, indent: true);
        MyLog.log(_classString, 'updateObject try creating:', level: Level.INFO, indent: true);
        _instance.collection(collection).doc(doc).set(map);
      }).catchError((onError) {
        MyLog.log(_classString, 'updateObject ERROR:', exception: onError, level: Level.SEVERE, indent: true);
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
      MyLog.log(_classString, 'deleteUser wrong id', myCustomObject: myUser, level: Level.SEVERE, indent: true);
    }

    // delete user
    try {
      MyLog.log(_classString, 'deleteUser user $myUser deleted');
      await _instance.collection(strDB(DBFields.users)).doc(myUser.id).delete();
    } catch (e) {
      MyLog.log(_classString, 'deleteUser error when deleting',
          myCustomObject: myUser, level: Level.SEVERE, indent: true);
    }
  }

  /// return match if user was inserted. null otherwise
  Future<MyMatch?> addPlayerToMatch({
    required Date matchId,
    required MyUser player,
    required AppState appState,
    int position = -1,
  }) async {
    MyLog.log(_classString, 'addPlayerToMatch adding user $player to $matchId position $position');
    DocumentReference documentReference = _instance.collection(strDB(DBFields.matches)).doc(matchId.toYyyyMMdd());

    return _instance.runTransaction((transaction) async {
      // get snapshot
      DocumentSnapshot snapshot = await transaction.get(documentReference);
      if (!snapshot.exists) {
        throw Exception('No existe el partido asociado a la fecha $matchId');
      }

      // get match
      MyMatch myMatch = MyMatch.fromJson(snapshot.data() as Map<String, dynamic>, appState);
      MyLog.log(_classString, 'addPlayerToMatch match = ', myCustomObject: myMatch, indent: true);

      // add player in memory match
      int posInserted = myMatch.insertPlayer(player, position: position);
      if (posInserted == -1) return null;
      MyLog.log(_classString, 'addPlayerToMatch inserted match = ', myCustomObject: myMatch, indent: true);

      // add match to firebase
      transaction.update(documentReference, myMatch.toJson(core: false, matchPlayers: true));
      return myMatch;
    }).catchError((onError) {
      MyLog.log(_classString, 'addPlayerToMatch error adding $player to match $matchId',
          level: Level.SEVERE, indent: true);
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
      MyLog.log(_classString, 'deletePlayerFromMatch match = ', myCustomObject: myMatch, indent: true);

      // delete player in match
      bool removed = myMatch.removePlayer(user);
      if (!removed) return null;
      MyLog.log(_classString, 'deletePlayerFromMatch removed match = ', myCustomObject: myMatch, indent: true);

      // add match to firebase
      transaction.update(documentReference, myMatch.toJson(core: false, matchPlayers: true));
      return myMatch;
    }).catchError((onError) {
      MyLog.log(_classString, 'deletePlayerFromMatch error deleting $user from match $matchId',
          level: Level.SEVERE, indent: true);
      throw Exception('Error al eliminar el jugador $user del partido $matchId\n'
          'Error = $onError');
    });
  }
}
