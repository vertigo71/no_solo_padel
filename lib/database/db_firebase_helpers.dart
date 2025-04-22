import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:simple_logger/simple_logger.dart';

import '../interface/if_app_state.dart';
import '../models/md_debug.dart';
import '../models/md_historic.dart';
import '../models/md_register.dart';
import '../models/md_match.dart';
import '../models/md_parameter.dart';
import '../models/md_user.dart';
import '../models/md_date.dart';
import '../models/md_result.dart';

final String _classString = '<db> FsHelper'.toLowerCase();

/// Firestore helpers
class FbHelpers {
  static final FbHelpers _singleton = FbHelpers._internal();

  factory FbHelpers() => _singleton;

  FbHelpers._internal() {
    MyLog.log(_classString, 'FbHelpers created', level: Level.FINE);
  }

  final FirebaseFirestore _instance = FirebaseFirestore.instance;
  StreamSubscription? _usersListener;
  StreamSubscription? _paramListener;

  /// return false if existed, true if created
  Future<bool> createMatchIfNotExists({required Date matchId}) async {
    bool exists = await doesDocExist(collection: MatchFs.matches.name, doc: matchId.toYyyyMmDd());
    if (exists) return false;
    MyLog.log(_classString, 'createMatchIfNotExists creating exist=$exists date=$matchId');
    await updateMatch(match: MyMatch(id: matchId, comment: ''), updateCore: true, updatePlayers: true);
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
    streamSubscription =
        _instance.collection(MatchFs.matches.name).doc(matchId.toYyyyMmDd()).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        MyMatch newMatch = MyMatch.fromJson(snapshot.data() as Map<String, dynamic>, appState);
        MyLog.log(_classString, 'listenToMatch LISTENER newMatch found = $newMatch', indent: true);
        matchFunction(newMatch);
      } else {
        MyLog.log(_classString, 'listenToMatch LISTENER Match data is null in Firestore.', indent: true);
        matchFunction(MyMatch(id: matchId, comment: appState.getParamValue(ParametersEnum.defaultCommentText)));
      }
    });

    return streamSubscription;
  }

  Future<void> createListeners({
    required void Function(MyParameters? parameters) parametersFunction,
    required void Function(List<MyUser> added, List<MyUser> modified, List<MyUser> removed) usersFunction,
  }) async {
    // update parameters
    if (_paramListener != null) {
      MyLog.log(_classString, 'ParamLISTENER already created', level: Level.WARNING, indent: true);
    } else {
      MyLog.log(_classString, 'creating ParamLISTENER ', indent: true);
      _paramListener =
          _instance.collection(ParameterFs.parameters.name).doc(ParameterFs.parameters.name).snapshots().listen(
        (snapshot) {
          MyParameters? myParameters;

          if (snapshot.exists && snapshot.data() != null) {
            MyLog.log(_classString, 'ParamLISTENER called: data found. loading parameters into appState ...',
                indent: true);
            myParameters = MyParameters.fromJson(snapshot.data() as Map<String, dynamic>);
          } else {
            MyLog.log(_classString, 'ParamLISTENER called: no new data found in Firestore',
                level: Level.WARNING, indent: true);
          }

          parametersFunction(myParameters ?? MyParameters());

          MyLog.log(_classString, 'ParamLISTENER: done', indent: true);
        },
        onError: (error) {
          MyLog.log(_classString, 'ParamLISTENER snapshot error: $error', level: Level.SEVERE, indent: true);
          throw Exception('Error de escucha. No se han podido cargar los parametros del sistema.\n$error');
        },
      );
    }

    // update users
    if (_usersListener != null) {
      MyLog.log(_classString, 'UserLISTENER already created', level: Level.WARNING, indent: true);
    } else {
      MyLog.log(_classString, 'creating UserLISTENER ', indent: true);
      _usersListener = _instance.collection(UserFs.users.name).snapshots().listen(
        (snapshot) {
          if (snapshot.docChanges.isNotEmpty) {
            MyLog.log(_classString, 'UserLISTENER called: data found. loading users into appState ...', indent: true);

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
                'UserLISTENER: users added=${addedUsers.length} mod=${modifiedUsers.length} '
                'removed=${removedUsers.length}',
                indent: true);
            usersFunction(addedUsers, modifiedUsers, removedUsers);
          } else {
            MyLog.log(_classString, 'UserLISTENER called: no new data found in Firestore',
                level: Level.WARNING, indent: true);
          }

          MyLog.log(_classString, 'UserLISTENER: done', indent: true);
        },
        onError: (error) {
          MyLog.log(_classString, 'UserLISTENER: onError loading users. Error: $error',
              level: Level.SEVERE, indent: true);
          throw Exception('Error de escucha. No se han podido cargar los usuarios del sistema.\n$error');
        },
      );
    }
  }

  Future<void> disposeListeners() async {
    MyLog.log(_classString, 'disposeListeners');
    await _usersListener?.cancel();
    await _paramListener?.cancel();
    _usersListener = null;
    _paramListener = null;
  }

  void _downloadChangedUsers({
    required QuerySnapshot snapshot,
    required List<MyUser> addedUsers,
    required List<MyUser> modifiedUsers,
    required List<MyUser> removedUsers,
  }) {
    MyLog.log(_classString, '_downloadChangedUsers update #users = ${snapshot.docChanges.length}');

    addedUsers.clear();
    modifiedUsers.clear();
    removedUsers.clear();

    for (var docChanged in snapshot.docChanges) {
      if (docChanged.doc.exists && docChanged.doc.data() != null) {
        Map<String, dynamic> data = docChanged.doc.data() as Map<String, dynamic>;

        try {
          MyUser user = MyUser.fromJson(data);
          MyLog.log(_classString, '_downloadChangedUsers user=$user', indent: true);

          if (user.hasBasicInfo()) {
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
          throw Exception('Error en la base de datos de usuarios. \nError: ${e.toString()}');
        }
      } else {
        MyLog.log(_classString, '_downloadChangedUsers ERROR data null', level: Level.WARNING, indent: true);
      }
    }
  }

  Stream<List<T>>? getStream<T>({
    required List<String> pathSegments, // List of collection/doc identifiers
    required T Function(Map<String, dynamic>, [AppState? appState]) fromJson,
    Date? fromDate,
    Date? toDate,
    AppState? appState,
    Query Function(Query)? filter,
    bool descending = false,
  }) {
    MyLog.log(_classString, 'getStream pathSegments=${pathSegments.join('/')}, filter=$filter');

    try {
      if (pathSegments.isEmpty || pathSegments.length % 2 == 0) {
        throw ArgumentError('Invalid pathSegments. Path must have an odd number of segments.');
      }

      CollectionReference collectionReference = FirebaseFirestore.instance.collection(pathSegments[0]);

      for (int i = 1; i < pathSegments.length; i += 2) {
        collectionReference = collectionReference.doc(pathSegments[i]).collection(pathSegments[i + 1]);
      }

      Query query = collectionReference;

      query = query.orderBy(FieldPath.documentId, descending: descending);

      if (fromDate != null) {
        query = query.where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMmDd());
      }
      if (toDate != null) {
        query = query.where(FieldPath.documentId, isLessThanOrEqualTo: toDate.toYyyyMmDd());
      }

      if (filter != null) {
        query = filter(query);
      }

      return query.snapshots().transform(_transformer(fromJson, appState));
    } catch (e) {
      MyLog.log(_classString, 'getStream ERROR pathSegments=${pathSegments.join('/')}',
          exception: e, level: Level.SEVERE, indent: true);
      throw Exception('Error leyendo datos de Firestore. Error de transformación.\nError: ${e.toString()}');
    }
  }

  // stream of messages registered
  Stream<List<RegisterModel>>? getRegisterStream(int fromDaysAgo) => getStream(
        pathSegments: [RegisterFs.register.name],
        fromJson: (json, [AppState? appState]) => RegisterModel.fromJson(json),
        fromDate: Date.now().subtract(Duration(days: fromDaysAgo)),
      );

  // stream of users
  Stream<List<MyUser>>? getUsersStream() => getStream(
        pathSegments: [UserFs.users.name],
        fromJson: (json, [AppState? appState]) => MyUser.fromJson(json),
      );

  Stream<List<MyMatch>>? getMatchesStream({
    required AppState appState,
    Date? fromDate,
    Date? toDate,
    bool onlyOpenMatches = false,
    bool descending = false,
  }) {
    MyLog.log(
        _classString,
        'getMatchesStream fromDate=$fromDate toDate=$toDate '
        'onlyOpenMatches=$onlyOpenMatches descending=$descending');

    return getStream(
      pathSegments: [MatchFs.matches.name],
      fromJson: (json, [AppState? optionalAppState]) => MyMatch.fromJson(json, appState),
      fromDate: fromDate,
      toDate: toDate,
      appState: appState,
      filter: onlyOpenMatches ? (query) => query.where('isOpen', isEqualTo: true) : null,
      descending: descending,
    );
  }

  Stream<List<GameResult>>? getResultsStream({
    required AppState appState,
    required String matchId,
  }) {
    MyLog.log(_classString, 'getResultsStream matchId=$matchId');

    return getStream(
      pathSegments: [MatchFs.matches.name, matchId, ResultFs.results.name],
      fromJson: (json, [AppState? optionalAppState]) => GameResult.fromJson(json, appState),
      appState: appState,
    );
  }

  Future<T?> getObject<T>({
    required List<String> pathSegments, // List of collection/doc identifiers
    required T Function(Map<String, dynamic>, [AppState? appState]) fromJson,
    AppState? appState,
  }) async {
    try {
      if (pathSegments.isEmpty || pathSegments.length % 2 != 0) {
        throw ArgumentError('Invalid pathSegments. Path must have an even number of segments.');
      }

      DocumentReference documentReference = FirebaseFirestore.instance.collection(pathSegments[0]).doc(pathSegments[1]);

      for (int i = 2; i < pathSegments.length; i += 2) {
        documentReference = documentReference.collection(pathSegments[i]).doc(pathSegments[i + 1]);
      }

      DocumentSnapshot documentSnapshot = await documentReference.get();

      Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;
      if (data != null && data.isNotEmpty) {
        T item = fromJson(data, appState);
        return item;
      } else {
        MyLog.log(_classString, 'getObject ${pathSegments.join('/')} not found or empty',
            level: Level.WARNING, indent: true);
      }
    } catch (e) {
      MyLog.log(_classString, 'getObject ${pathSegments.join('/')}', exception: e, level: Level.SEVERE, indent: true);
      throw Exception('Error al obtener el objeto ${pathSegments.join('/')}. \nError: ${e.toString()}');
    }
    return null;
  }

  Future<MyUser?> getUser(String userId) async => getObject(
      pathSegments: [UserFs.users.name, userId], fromJson: (json, [AppState? appState]) => MyUser.fromJson(json));

  Future<MyMatch?> getMatch(String matchId, AppState appState) async => getObject(
      pathSegments: [MatchFs.matches.name, matchId],
      fromJson: (json, [AppState? optionalAppState]) => MyMatch.fromJson(json, appState),
      appState: appState);

  Future<GameResult?> getResult(
          {required String matchId, required String resultId, required AppState appState}) async =>
      await getObject(
          pathSegments: [MatchFs.matches.name, matchId, ResultFs.results.name, resultId],
          fromJson: (json, [AppState? optionalAppState]) => GameResult.fromJson(json, appState));

  Future<MyParameters> getParameters() async =>
      await getObject(
          pathSegments: [ParameterFs.parameters.name, ParameterFs.parameters.name],
          fromJson: (json, [AppState? appState]) => MyParameters.fromJson(json)) ??
      MyParameters();

  Future<Historic?> getHistoric(Date date) async => await getObject(
      pathSegments: [HistoricFs.historic.name, date.toYyyyMmDd()],
      fromJson: (json, [AppState? appState]) => Historic.fromJson(json));

  Future<List<T>> getAllObjects<T>({
    required List<String> pathSegments, // List of collection/doc identifiers
    required T Function(Map<String, dynamic>, [AppState? appState]) fromJson,
    Date? fromDate,
    Date? toDate,
    AppState? appState,
    Query Function(Query)? filter,
  }) async {
    MyLog.log(_classString, 'getAllObjects');

    List<T> items = [];
    try {
      if (pathSegments.isEmpty || pathSegments.length % 2 == 0) {
        throw ArgumentError('Invalid pathSegments. Path must have an odd number of segments.');
      }

      CollectionReference collectionReference = FirebaseFirestore.instance.collection(pathSegments[0]);

      for (int i = 1; i < pathSegments.length; i += 2) {
        collectionReference = collectionReference.doc(pathSegments[i]).collection(pathSegments[i + 1]);
      }

      Query query = collectionReference;

      if (fromDate != null) {
        query = query.where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMmDd());
      }
      if (toDate != null) {
        query = query.where(FieldPath.documentId, isLessThanOrEqualTo: toDate.toYyyyMmDd());
      }

      if (filter != null) {
        query = filter(query);
      }

      QuerySnapshot querySnapshot = await query.get();
      for (var doc in querySnapshot.docs) {
        if (doc.data() == null) throw 'Error en la base de datos ${pathSegments.join('/')}';
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        T item = fromJson(data, appState);

        MyLog.log(_classString, 'getAllObjects ${pathSegments.join('/')} = $item', indent: true);
        items.add(item);
      }
    } catch (e) {
      MyLog.log(_classString, 'getAllObjects', exception: e, level: Level.SEVERE, indent: true);
      throw Exception('Error al obtener los objetos ${pathSegments.join('/')}. \nError: ${e.toString()}');
    }
    MyLog.log(_classString, 'getAllObjects #${pathSegments.join('/')} = ${items.length} ', indent: true);
    return items;
  }

  Future<List<MyUser>> getAllUsers() async => getAllObjects<MyUser>(
        pathSegments: [UserFs.users.name],
        fromJson: (json, [AppState? appState]) => MyUser.fromJson(json),
      );

  Future<List<MyMatch>> getAllMatches(AppState appState) async => getAllObjects<MyMatch>(
        pathSegments: [MatchFs.matches.name],
        fromJson: (json, [AppState? optionalAppState]) => MyMatch.fromJson(json, appState),
      );

  /// returns all matches containing a player
  Future<List<MyMatch>> getAllPlayerMatches({
    required AppState appState,
    required String playerId,
    Date? fromDate,
    Date? toDate,
  }) async {
    return getAllObjects<MyMatch>(
      pathSegments: [MatchFs.matches.name],
      fromJson: (json, [AppState? optionalAppState]) => MyMatch.fromJson(json, appState),
      // Unified call
      fromDate: fromDate,
      toDate: toDate,
      appState: appState,
      filter: (query) => query.where(MatchFs.players.name, arrayContains: playerId),
    );
  }

  /// returns all results from a match
  Future<List<GameResult>> getAllMatchResults({
    required String matchId,
    required AppState appState,
  }) async {
    return getAllObjects<GameResult>(
      pathSegments: [MatchFs.matches.name, matchId, ResultFs.results.name],
      fromJson: (json, [AppState? optionalAppState]) => GameResult.fromJson(json, appState),
      appState: appState,
    );
  }

  Future<void> updateObject({
    required Map<String, dynamic> fields,
    required List<String> pathSegments, // List of collection/doc identifiers
    bool forceSet = false,
  }) async {
    MyLog.log(_classString, 'updateObject ${pathSegments.join('/')}, forceSet: $forceSet', indent: true);

    try {
      if (pathSegments.isEmpty || pathSegments.length % 2 != 0) {
        throw ArgumentError('Invalid pathSegments. Path must have an even number of segments.');
      }

      DocumentReference documentReference = FirebaseFirestore.instance.collection(pathSegments[0]).doc(pathSegments[1]);

      for (int i = 2; i < pathSegments.length; i += 2) {
        documentReference = documentReference.collection(pathSegments[i]).doc(pathSegments[i + 1]);
      }

      await documentReference.set(fields, SetOptions(merge: !forceSet));

      MyLog.log(_classString, 'updateObject ${pathSegments.join('/')}, success', indent: true);
    } catch (onError) {
      MyLog.log(_classString, 'updateObject ${pathSegments.join('/')} error:', exception: onError, level: Level.SEVERE);
      throw Exception('Error al actualizar ${pathSegments.join('/')}. \nError: $onError');
    }
  }

  Future<void> updateUser(final MyUser user, [Uint8List? compressedImageData]) async {
    MyLog.log(_classString, 'updateUser = $user');
    if (user.id == '') {
      MyLog.log(_classString, 'updateUser ', myCustomObject: user, level: Level.SEVERE);
      throw Exception('Error: el usuario no tiene id. No se puede actualizar.');
    }
    if (compressedImageData != null) {
      user.avatarUrl = await _uploadDataToStorage('${UserFs.avatars.name}/${user.id}', compressedImageData);
    }
    await updateObject(
      fields: user.toJson(),
      pathSegments: [UserFs.users.name, user.id],
      forceSet: false, // replaces the old object if exists
    );
  }

  /// set all users ranking to newRanking
  /// make all users inactive by removing past matches
  Future<void> resetUsersBatch({required int newRanking, required Date deleteMatchesToDate}) async {
    MyLog.log(_classString, 'resetUsersBatch = $newRanking');
    final usersCollection = FirebaseFirestore.instance.collection(UserFs.users.name);

    // 1. Retrieve user documents
    final querySnapshot = await usersCollection.get();

    final batches = <WriteBatch>[];
    var currentBatch = FirebaseFirestore.instance.batch();
    var operationsInBatch = 0;

    // 2. Create batched writes
    for (final docSnapshot in querySnapshot.docs) {
      // Accessing the 'matchIds' array of Strings:
      final List<String> matchIds = docSnapshot.data()[UserFs.matchIds.name]?.cast<String>() ?? [];

      matchIds.removeWhere((e) {
        Date? eDate = Date.parse(e);
        if (eDate == null) {
          MyLog.log(_classString, 'resetUsersBatch Wrong Format matches=$e', level: Level.WARNING, indent: true);
          return false;
        }
        return eDate.compareTo(deleteMatchesToDate) <= 0; // before or equal to deleteMatchesToDate
      });

      currentBatch.update(docSnapshot.reference, {UserFs.rankingPos.name: newRanking, UserFs.matchIds.name: matchIds});
      operationsInBatch++;

      // Firestore batch limit is typically 500, so create new batch when needed.
      if (operationsInBatch >= 499) {
        MyLog.log(_classString, 'resetUsersBatch Creating new batch.', indent: true);

        batches.add(currentBatch);
        currentBatch = FirebaseFirestore.instance.batch();
        operationsInBatch = 0;
      }
    }

    //add any remaining operations.
    if (operationsInBatch > 0) {
      batches.add(currentBatch);
    }

    // 3. Commit batches
    for (final batch in batches) {
      await batch.commit();
    }

    MyLog.log(_classString, 'resetUsersBatch Done. Batches=${batches.length} Operations=$operationsInBatch.',
        indent: true);
  }

  /// core = comment + isOpen + courtNames (all except players)
  Future<void> updateMatch({required MyMatch match, required bool updateCore, required bool updatePlayers}) async =>
      await updateObject(
        fields: match.toJson(core: updateCore, matchPlayers: updatePlayers),
        pathSegments: [MatchFs.matches.name, match.id.toYyyyMmDd()],
        forceSet: false, // replaces the old object if exists
      );

  Future<void> updateResult({required GameResult result, required String matchId}) async => await updateObject(
        fields: result.toJson(),
        pathSegments: [MatchFs.matches.name, matchId, ResultFs.results.name, result.id.resultId],
        forceSet: false, // replaces the old object if exists
      );

  Future<void> updateHistoric({required Historic historic}) async => await updateObject(
        fields: historic.toJson(),
        pathSegments: [HistoricFs.historic.name, historic.id.toYyyyMmDd()],
        forceSet: false, // replaces the old object if exists
      );

  Future<void> updateRegister(RegisterModel registerModel) async => await updateObject(
        fields: registerModel.toJson(),
        pathSegments: [RegisterFs.register.name, registerModel.date.toYyyyMmDd()],
        forceSet: false, // replaces the old object if exists
      );

  Future<void> updateParameters(MyParameters myParameters) async => await updateObject(
        fields: myParameters.toJson(),
        pathSegments: [ParameterFs.parameters.name, ParameterFs.parameters.name],
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
      await _instance.collection(UserFs.users.name).doc(myUser.id).delete();
    } catch (e) {
      MyLog.log(_classString, 'deleteUser error when deleting',
          myCustomObject: myUser, level: Level.SEVERE, indent: true);
      throw Exception('Error al eliminar el usuario $myUser. \nError: ${e.toString()}');
    }
  }

  Future<void> deleteResult(GameResult result) async {
    MyLog.log(_classString, 'deleteResult deleting result $result');

    try {
      await _instance
          .collection(MatchFs.matches.name)
          .doc(result.matchId.toYyyyMmDd())
          .collection(ResultFs.results.name)
          .doc(result.id.resultId)
          .delete();
    } catch (e) {
      MyLog.log(_classString, 'deleteResult error when deleting',
          myCustomObject: result, level: Level.SEVERE, indent: true);
      rethrow;
    }
  }

  Future<void> deleteDocsBatch(
      {required String collection, String? subcollection, Date? fromDate, Date? toDate}) async {
    MyLog.log(_classString,
        'deleteObjectsBatch $collection/$subcollection: fromDate=${fromDate?.toYyyyMmDd()}, toDate=${toDate?.toYyyyMmDd()}');

    // 0. Create query
    Query query = FirebaseFirestore.instance.collection(collection);

    query = query.orderBy(FieldPath.documentId);

    if (fromDate != null) {
      query = query.where(FieldPath.documentId, isGreaterThanOrEqualTo: fromDate.toYyyyMmDd());
    }
    if (toDate != null) {
      query = query.where(FieldPath.documentId, isLessThanOrEqualTo: toDate.toYyyyMmDd());
    }

    final querySnapshot = await query.get();

    final batches = <WriteBatch>[];
    WriteBatch currentBatch = FirebaseFirestore.instance.batch();
    int operationsInBatch = 0;

    // inline function to add doc to batch
    // updates currentBatch and operationsInBatch
    void addDocToBatch(DocumentReference reference) {
      currentBatch.delete(reference);
      operationsInBatch++;
      if (operationsInBatch >= 499) {
        MyLog.log(_classString, 'deleteObjectsBatch Creating new batch for subcollection.', indent: true);
        batches.add(currentBatch);
        currentBatch = FirebaseFirestore.instance.batch();
        operationsInBatch = 0;
      }
    }

    for (final docSnapshot in querySnapshot.docs) {
      if (subcollection != null) {
        final subCollectionRef = docSnapshot.reference.collection(subcollection);
        final subCollectionDocs = await subCollectionRef.get();
        for (final subDoc in subCollectionDocs.docs) {
          MyLog.log(_classString, 'deleteObjectsBatch $collection=${docSnapshot.id}/$subcollection=${subDoc.id}',
              indent: true);
          addDocToBatch(subDoc.reference);
        }
      }
      MyLog.log(_classString, 'deleteObjectsBatch $collection ${docSnapshot.id}', indent: true);
      addDocToBatch(docSnapshot.reference);
    }

    if (operationsInBatch > 0) {
      batches.add(currentBatch);
    }

    for (final batch in batches) {
      await batch.commit();
    }

    MyLog.log(
        _classString,
        'deleteObjectsBatch $collection/$subcollection Done. Batches=${batches.length} '
        'Operations=${querySnapshot.size} + ${subcollection != null ? " (plus subcollections)" : ""}.',
        indent: true);
  }

  /// return match with the position of inserted user
  /// add match to the user's list of matches
  Future<Map<MyMatch, int>> addPlayerToMatch({
    required Date matchId,
    required MyUser player,
    required AppState appState,
    int position = -1,
  }) async {
    MyLog.log(_classString, 'addPlayerToMatch adding user $player to $matchId position $position');
    DocumentReference matchDocReference = _instance.collection(MatchFs.matches.name).doc(matchId.toYyyyMmDd());
    DocumentReference userDocReference = _instance.collection(UserFs.users.name).doc(player.id);

    return await _instance.runTransaction((transaction) async {
      // get snapshots
      DocumentSnapshot matchSnapshot = await transaction.get(matchDocReference);

      // get match or create a new one
      late MyMatch myMatch;
      if (matchSnapshot.exists && matchSnapshot.data() != null) {
        // get match
        myMatch = MyMatch.fromJson(matchSnapshot.data() as Map<String, dynamic>, appState);
        MyLog.log(_classString, 'addPlayerToMatch match found ', myCustomObject: myMatch, indent: true);
      } else {
        // get match
        myMatch = MyMatch(id: matchId, comment: appState.getParamValue(ParametersEnum.defaultCommentText));
        MyLog.log(_classString, 'addPlayerToMatch NEW match ', indent: true);
      }

      // add player to memory match
      int posInserted = myMatch.insertPlayer(player, position: position);
      // exception caught by catchError
      if (posInserted == -1) throw Exception('Error: el jugador ya estaba en el partido.');
      MyLog.log(_classString, 'addPlayerToMatch inserted match = ', myCustomObject: myMatch, indent: true);

      // add match to user
      bool added = player.addMatchId(matchId.toYyyyMmDd(), true);

      // add/update match to firebase
      transaction.set(
        matchDocReference,
        myMatch.toJson(core: false, matchPlayers: true),
        SetOptions(merge: true),
      );
      // add/update user to firebase
      if (added) {
        transaction.set(
          userDocReference,
          player.toJson(),
          SetOptions(merge: true),
        );
      }

      // Return the map with MyMatch and player position
      return {myMatch: posInserted};
    }).catchError((e) {
      MyLog.log(_classString, 'addPlayerToMatch error adding $player to match $matchId',
          exception: e, level: Level.WARNING, indent: true);
      throw Exception('Error al añadir jugador $player al partido $matchId\n'
          'Error = ${e.toString()}');
    });
  }

  /// return match
  Future<MyMatch> deletePlayerFromMatch({
    required Date matchId,
    required MyUser player,
    required AppState appState,
  }) async {
    MyLog.log(_classString, 'deletePlayerFromMatch deleting user $player from $matchId');
    DocumentReference matchDocReference = _instance.collection(MatchFs.matches.name).doc(matchId.toYyyyMmDd());
    DocumentReference userDocReference = _instance.collection(UserFs.users.name).doc(player.id);

    return await _instance.runTransaction((transaction) async {
      // get match
      DocumentSnapshot matchSnapshot = await transaction.get(matchDocReference);

      late MyMatch myMatch;
      if (matchSnapshot.exists && matchSnapshot.data() != null) {
        // get match
        myMatch = MyMatch.fromJson(matchSnapshot.data() as Map<String, dynamic>, appState);
        MyLog.log(_classString, 'deletePlayerFromMatch match found ', myCustomObject: myMatch, indent: true);
      } else {
        // get match
        myMatch = MyMatch(id: matchId, comment: appState.getParamValue(ParametersEnum.defaultCommentText));
        MyLog.log(_classString, 'deletePlayerFromMatch NEW match ', indent: true);
      }

      // delete player in match
      bool removed = myMatch.removePlayer(player);
      // exception caught by catchError
      if (!removed) throw Exception('Error: el jugador no estaba en el partido.');
      MyLog.log(_classString, 'deletePlayerFromMatch removed match = ', myCustomObject: myMatch, indent: true);

      // remove match from user
      bool removedUser = player.removeMatchId(matchId.toYyyyMmDd());

      // add match to firebase
      transaction.set(
        matchDocReference,
        myMatch.toJson(core: false, matchPlayers: true),
        SetOptions(merge: true),
      );

      // remove user from firebase
      if (removedUser) {
        transaction.set(
          userDocReference,
          player.toJson(),
          SetOptions(merge: true),
        );
      }

      return myMatch;
    }).catchError((onError) {
      MyLog.log(_classString, 'deletePlayerFromMatch error deleting $player from match $matchId',
          exception: onError, level: Level.SEVERE, indent: true);
      throw Exception('Error al eliminar el jugador $player del partido $matchId\n'
          'Error = $onError');
    });
  }

  Future saveAllUsersToHistoric() async {
    MyLog.log(_classString, 'saveAllUsersToHistoric');
    List<MyUser> allUsers = await getAllUsers();

    Historic historic = Historic.fromUsers(id: Date.now(), users: allUsers);
    await updateHistoric(historic: historic);
  }

  /// Uploads raw data (Uint8List) to Firebase Storage.
  ///
  /// This function takes a filename and raw data as input, uploads the data to
  /// Firebase Storage under the specified filename, and returns the download URL
  /// of the uploaded file if the upload is successful.
  ///
  /// Parameters:
  ///   filename: The name of the file to be uploaded (including path if needed).
  ///   data: The raw data (Uint8List) to be uploaded.
  ///
  /// Returns:
  ///   A Future that completes with the download URL of the uploaded file (String)
  ///   if the upload is successful, or null if the upload fails.
  ///
  /// Throws:
  ///   An Exception if the upload fails, containing the error message
  Future<String?> _uploadDataToStorage(final String filename, final Uint8List data) async {
    MyLog.log(_classString, 'Uploading new file', indent: true);

    // Create a reference to the storage location where the file will be uploaded.
    final Reference storageRef = FirebaseStorage.instance.ref().child(filename);

    // Start the upload task by putting the raw data to the storage reference.
    final UploadTask uploadTask = storageRef.putData(data);

    try {
      // Wait for the upload task to complete and get the task snapshot.
      final TaskSnapshot snapshot = await uploadTask;

      // Check if the upload was successful.
      if (snapshot.state == TaskState.success) {
        // Get the download URL of the uploaded file.
        String fileUrl = await snapshot.ref.getDownloadURL();

        MyLog.log(_classString, 'File uploaded successfully: $fileUrl', indent: true);

        // Return the download URL.
        return fileUrl;
      } else {
        // If the upload failed, log the error and throw an exception.
        MyLog.log(_classString, 'File upload failed: ${snapshot.state}', level: Level.SEVERE);
        throw Exception('(Estado=${snapshot.state})');
      }
    } catch (e) {
      // If an exception occurred during the upload, log the error and throw an exception.
      MyLog.log(_classString, 'File upload failed: ${e.toString()}', level: Level.SEVERE);
      throw Exception('Error al subir el archivo $filename\nError: ${e.toString()}');
    }
  }

  // StreamTransformer.fromHandlers and handleData
  //
  // StreamTransformer.fromHandlers: This is a convenient factory constructor for creating a StreamTransformer.
  // It allows you to define the transformation logic using handler functions.
  //
  // handleData: (QuerySnapshot<Map<String, dynamic>> data, EventSink<List<T>> sink):
  // data: This is where the magic happens. The data parameter receives the QuerySnapshot<Map<String, dynamic>>
  // emitted by the input stream (query.snapshots()).
  // So, every time there is a change in the query result,
  // the new QuerySnapshot is passed to the handleData function.
  // sink: The EventSink<List<T>> is the output sink. You use it to send the transformed data (a List<T>)
  // to the output stream. It is how you add data to the transformed stream.
  // How data gets here: When query.snapshots().transform(transformer(fromJson, appState)) is executed,
  // the bind method of the stream transformer is called. The bind method then attaches the handleData function
  // to the input stream. So that every time a new event happens on the input stream,
  // the handleData function is triggered, and the event data is passed as the data parameter.
  StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<T>> _transformer<T>(
    T Function(Map<String, dynamic>, [AppState? appState]) fromJson,
    AppState? appState,
  ) {
    return StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<T>>.fromHandlers(
      handleData: (QuerySnapshot<Map<String, dynamic>> snapshot, EventSink<List<T>> sink) {
        List<T> items = snapshot.docs.map((doc) => fromJson(doc.data(), appState)).toList();
        sink.add(items);
      },
      handleError: (error, stackTrace, sink) {
        sink.addError(error, stackTrace);
      },
    );
  }
}
