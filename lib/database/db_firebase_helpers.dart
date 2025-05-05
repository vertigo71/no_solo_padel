import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:simple_logger/simple_logger.dart';

import '../interface/if_app_state.dart';
import '../models/md_debug.dart';
import '../models/md_exception.dart';
import '../models/md_historic.dart';
import '../models/md_register.dart';
import '../models/md_match.dart';
import '../models/md_parameter.dart';
import '../models/md_user.dart';
import '../models/md_date.dart';
import '../models/md_result.dart';
import '../models/md_user_match_result.dart';

final String _classString = '<db> FsHelper'.toLowerCase();
final FirebaseFirestore _instance = FirebaseFirestore.instance;

mixin _Basic {
  DocumentReference _getDocRef({required List<String> pathSegments}) {
    if (pathSegments.isEmpty || pathSegments.length % 2 != 0) {
      throw MyException('Invalid pathSegments. Path must have an even number of segments.', level: Level.SEVERE);
    }

    DocumentReference documentReference = FirebaseFirestore.instance.collection(pathSegments[0]).doc(pathSegments[1]);

    for (int i = 2; i < pathSegments.length; i += 2) {
      documentReference = documentReference.collection(pathSegments[i]).doc(pathSegments[i + 1]);
    }

    return documentReference;
  }

  CollectionReference _getCollectionRef({
    required List<String> pathSegments, // List of collection/doc identifiers
  }) {
    if (pathSegments.isEmpty || pathSegments.length % 2 == 0) {
      throw MyException('Invalid pathSegments. Path must have an odd number of segments.', level: Level.SEVERE);
    }

    CollectionReference collectionReference = FirebaseFirestore.instance.collection(pathSegments[0]);

    for (int i = 1; i < pathSegments.length; i += 2) {
      collectionReference = collectionReference.doc(pathSegments[i]).collection(pathSegments[i + 1]);
    }

    return collectionReference;
  }

  Query _getQuery({
    required List<String> pathSegments, // List of collection/doc identifiers
    String? sortingField, // if field is null, uses FieldPath.documentId
    required bool descending,
    String? minDocId,
    String? maxDocId,
    Query Function(Query)? filter,
  }) {
    Query query = _getCollectionRef(pathSegments: pathSegments);

    // mandatory sorting when using > < filtering
    query = query.orderBy((sortingField != null) ? sortingField : FieldPath.documentId, descending: descending);

    if (minDocId != null) {
      query =
          query.where((sortingField != null) ? sortingField : FieldPath.documentId, isGreaterThanOrEqualTo: minDocId);
    }
    if (maxDocId != null) {
      query = query.where((sortingField != null) ? sortingField : FieldPath.documentId, isLessThanOrEqualTo: maxDocId);
    }

    if (filter != null) {
      query = filter(query);
    }

    return query;
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
        throw MyException('(Estado=${snapshot.state})', level: Level.SEVERE);
      }
    } catch (e) {
      // If an exception occurred during the upload, log the error and throw an exception.
      MyLog.log(_classString, 'File upload failed: ${e.toString()}', level: Level.SEVERE);
      throw MyException('Error al subir el archivo $filename', e: e, level: Level.SEVERE);
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

mixin _GetObject implements _Basic {
  Future<T?> _getObject<T>({
    required List<String> pathSegments, // List of collection/doc identifiers
    required T Function(Map<String, dynamic>, [AppState? appState]) fromJson,
    AppState? appState,
  }) async {
    try {
      DocumentReference documentReference = _getDocRef(pathSegments: pathSegments);
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
      throw MyException('Error al obtener el objeto ${pathSegments.join('/')}', e: e, level: Level.SEVERE);
    }
    return null;
  }

  Future<MyUser?> getUser(String userId) async => _getObject(
      pathSegments: [UserFs.users.name, userId], fromJson: (json, [AppState? appState]) => MyUser.fromJson(json));

  Future<MyMatch?> getMatch(String matchId, AppState appState) async => _getObject(
      pathSegments: [MatchFs.matches.name, matchId],
      fromJson: (json, [AppState? optionalAppState]) => MyMatch.fromJson(json, appState),
      appState: appState);

  Future<GameResult?> getGameResult(
          { required String resultId, required AppState appState}) async =>
      await _getObject(
          pathSegments: [GameResultFs.results.name, resultId],
          fromJson: (json, [AppState? optionalAppState]) => GameResult.fromJson(json, appState));

  Future<UserMatchResult?> getUserMatchResult({required String userMatchResultId}) async => await _getObject(
      pathSegments: [UserMatchResultFs.userMatchResult.name, userMatchResultId],
      fromJson: (json, [AppState? optionalAppState]) => UserMatchResult.fromJson(json));

  Future<MyParameters> getParameters() async =>
      await _getObject(
          pathSegments: [ParameterFs.parameters.name, ParameterFs.parameters.name],
          fromJson: (json, [AppState? appState]) => MyParameters.fromJson(json)) ??
      MyParameters();

  Future<Historic?> getHistoric(Date date) async => await _getObject(
      pathSegments: [HistoricFs.historic.name, date.toYyyyMmDd()],
      fromJson: (json, [AppState? appState]) => Historic.fromJson(json));
}

mixin _GetObjects implements _Basic {
  /// fromJson == null => gets a list of documentIds (T must be String)
  Future<List<T>> _getAllObjects<T>({
    required List<String> pathSegments,
    T Function(Map<String, dynamic>, [AppState? appState])? fromJson,
    Date? fromDate,
    Date? toDate,
    AppState? appState,
    // bool descending = false, need an index that cannot be created in Firestore console
    Query Function(Query)? filter,
  }) async {
    MyLog.log(_classString, 'getAllObjects ${pathSegments.join('/')}');

    List<T> items = [];
    try {
      Query query = _getQuery(
        pathSegments: pathSegments,
        descending: false,
        minDocId: fromDate?.toYyyyMmDd(),
        maxDocId: toDate?.toYyyyMmDd(),
        filter: filter,
      );

      QuerySnapshot querySnapshot = await query.get();

      for (var doc in querySnapshot.docs) {
        if (doc.data() == null) {
          throw MyException('No hay datos al obtener los objetos de ${pathSegments.join('/')}', level: Level.SEVERE);
        }
        if (fromJson == null) {
          assert(T == String, 'T must be String');
          MyLog.log(_classString, 'getAllObjects ${pathSegments.join('/')} = ${doc.id}', indent: true);
          items.add(doc.id as T);
        } else {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          T item = fromJson(data, appState);
          MyLog.log(_classString, 'getAllObjects ${pathSegments.join('/')} = $item', indent: true);
          items.add(item);
        }
      }
    } catch (e) {
      MyLog.log(_classString, 'getAllObjects  ${pathSegments.join('/')} ERROR ',
          exception: e, level: Level.SEVERE, indent: true);
      throw MyException('Error al obtener los objetos ${pathSegments.join('/')}', e: e, level: Level.SEVERE);
    }
    MyLog.log(_classString, 'getAllObjects #${pathSegments.join('/')} = ${items.length} ', indent: true);
    return items;
  }

  Future<List<MyUser>> getAllUsers() async => _getAllObjects<MyUser>(
        pathSegments: [UserFs.users.name],
        fromJson: (json, [AppState? appState]) => MyUser.fromJson(json),
      );

  Future<List<MyMatch>> getAllMatches({
    required AppState appState,
    Date? fromDate,
    Date? toDate,
    // bool descending = false, need an index that cannot be created in Firestore console
  }) async =>
      _getAllObjects<MyMatch>(
        pathSegments: [MatchFs.matches.name],
        fromDate: fromDate,
        toDate: toDate,
        fromJson: (json, [AppState? optionalAppState]) => MyMatch.fromJson(json, appState),
      );

  Future<List<GameResult>> getAllGameResults({
    required AppState appState,
    Date? fromDate,
    Date? toDate,
    // bool descending = false, need an index that cannot be created in Firestore console
  }) async =>
      _getAllObjects<GameResult>(
        pathSegments: [GameResultFs.results.name],
        fromDate: fromDate,
        toDate: toDate,
        fromJson: (json, [AppState? optionalAppState]) => GameResult.fromJson(json, appState),
      );

  /// returns all matches containing a player
  Future<List<MyMatch>> getAllMatchesWithPlayer({
    required AppState appState,
    required String playerId,
    Date? fromDate,
    Date? toDate,
  }) async {
    return _getAllObjects<MyMatch>(
      pathSegments: [MatchFs.matches.name],
      fromJson: (json, [AppState? optionalAppState]) => MyMatch.fromJson(json, appState),
      fromDate: fromDate,
      toDate: toDate,
      appState: appState,
      filter: (query) => query.where(MatchFs.players.name, arrayContains: playerId),
    );
  }

  /// returns all results from a match
  Future<List<GameResult>> getAllGameResultsFromMatch({
    required String matchId,
    required AppState appState,
    // bool descending = false, need an index that cannot be created in Firestore console
  }) async {
    return _getAllObjects<GameResult>(
      pathSegments: [GameResultFs.results.name],
      fromJson: (json, [AppState? optionalAppState]) => GameResult.fromJson(json, appState),
      appState: appState,
      filter: (query) => query.where(GameResultFs.matchId.name, isEqualTo: matchId),
    );
  }

  Future<List<UserMatchResult>> getUserMatchResults({
    String? userId,
    String? matchId,
    String? resultId,
    // bool descending = false, need an index
  }) async {
    return _getAllObjects<UserMatchResult>(
      pathSegments: [UserMatchResultFs.userMatchResult.name],
      fromJson: (json, [AppState? optionalAppState]) => UserMatchResult.fromJson(json),
      filter: (query) {
        if (userId != null) query = query.where(UserMatchResultFs.userId.name, isEqualTo: userId);
        if (matchId != null) query = query.where(UserMatchResultFs.matchId.name, isEqualTo: matchId);
        if (resultId != null) query = query.where(UserMatchResultFs.resultId.name, isEqualTo: resultId);
        return query;
      },
    );
  }

  // @Deprecated('To be removed')
  // Future<List<GameResult>> getResultsOfAMatchOldFormat({
  //   required String matchId,
  //   required AppState appState,
  //   // bool descending = false, need an index
  // }) async {
  //   return _getAllObjects<GameResult>(
  //     pathSegments: [MatchFs.matches.name, matchId, GameResultFs.results.name],
  //     fromJson: (json, [AppState? optionalAppState]) => GameResult.fromJsonOldFormat(json, appState),
  //   );
  // }

  Future<List<String>> getUserMatchResultIds({
    String? userId,
    String? matchId,
    String? resultId,
    // bool descending = false, need an index
  }) async {
    return _getAllObjects<String>(
      pathSegments: [UserMatchResultFs.userMatchResult.name],
      filter: (query) {
        if (userId != null) query = query.where(UserMatchResultFs.userId.name, isEqualTo: userId);
        if (matchId != null) query = query.where(UserMatchResultFs.matchId.name, isEqualTo: matchId);
        if (resultId != null) query = query.where(UserMatchResultFs.resultId.name, isEqualTo: resultId);
        return query;
      },
    );
  }
}

mixin _UpdateObject implements _Basic {
  Future<void> _updateObject({
    required Map<String, dynamic> fields,
    required List<String> pathSegments, // List of collection/doc identifiers
    bool forceSet = false, // false: merges the fields, true:replaces the old object if exists
  }) async {
    MyLog.log(_classString, 'updateObject ${pathSegments.join('/')}, forceSet: $forceSet', indent: true);

    try {
      DocumentReference documentReference = _getDocRef(pathSegments: pathSegments);
      await documentReference.set(fields, SetOptions(merge: !forceSet));

      MyLog.log(_classString, 'updateObject ${pathSegments.join('/')}, success', indent: true);
    } catch (onError) {
      MyLog.log(_classString, 'updateObject ${pathSegments.join('/')} error:', exception: onError, level: Level.SEVERE);
      throw MyException('Error al actualizar ${pathSegments.join('/')}', e: onError, level: Level.SEVERE);
    }
  }

  Future<void> updateUser(final MyUser user, [Uint8List? compressedImageData]) async {
    MyLog.log(_classString, 'updateUser = $user');
    if (user.id == '') {
      MyLog.log(_classString, 'updateUser ', myCustomObject: user, level: Level.SEVERE);
      throw MyException('Error: el usuario no tiene id. No se puede actualizar.', level: Level.SEVERE);
    }
    if (compressedImageData != null) {
      user.avatarUrl = await _uploadDataToStorage('${UserFs.avatars.name}/${user.id}', compressedImageData);
    }
    await _updateObject(
      fields: user.toJson(),
      pathSegments: [UserFs.users.name, user.id],
      forceSet: false, // false: merges the fields, true:replaces the old object if exists
    );
  }

  /// core = comment + isOpen + courtNames (all except players)
  Future<void> updateMatchOnlyCore({required MyMatch match}) async => await _updateObject(
        fields: match.toJson(core: true, matchPlayers: false),
        pathSegments: [MatchFs.matches.name, match.id.toYyyyMmDd()],
        forceSet: false, // false: merges the fields, true:replaces the old object if exists
      );

  Future<void> updateHistoric({required Historic historic}) async => await _updateObject(
        fields: historic.toJson(),
        pathSegments: [HistoricFs.historic.name, historic.id.toYyyyMmDd()],
        forceSet: false, // false: merges the fields, true:replaces the old object if exists
      );

  Future<void> updateRegister(RegisterModel registerModel) async => await _updateObject(
        fields: registerModel.toJson(),
        pathSegments: [RegisterFs.register.name, registerModel.date.toYyyyMmDd()],
        forceSet: false, // false: merges the fields, true:replaces the old object if exists
      );

  Future<void> updateParameters(MyParameters myParameters) async => await _updateObject(
        fields: myParameters.toJson(),
        pathSegments: [ParameterFs.parameters.name, ParameterFs.parameters.name],
        forceSet: true, // false: merges the fields, true:replaces the old object if exists
      );
}

mixin _DeleteObject implements _Basic {
  Future<void> _batchProcessing({
    required QuerySnapshot querySnapshot,
    required Future Function(WriteBatch batch, DocumentSnapshot docSnapshot) processDocument,
  }) async {
    MyLog.log(_classString, '_batchProcessing Starting batch processing...');

    final batches = <WriteBatch>[];
    var currentBatch = FirebaseFirestore.instance.batch();
    var operationsInBatch = 0;

    for (final docSnapshot in querySnapshot.docs) {
      MyLog.log(_classString, '_batchProcessing Processing document: ${docSnapshot.id}',
          indent: true, level: Level.FINE);

      await processDocument(currentBatch, docSnapshot);
      operationsInBatch++;

      if (operationsInBatch >= 499) {
        MyLog.log(_classString, '_batchProcessing Creating new batch=${batches.length}', indent: true);
        batches.add(currentBatch);
        currentBatch = FirebaseFirestore.instance.batch();
        operationsInBatch = 0;
      }
    }

    if (operationsInBatch > 0) {
      batches.add(currentBatch);
    }

    for (final batch in batches) {
      await batch.commit();
    }

    int totalOperations = batches.length * 500 + operationsInBatch;
    MyLog.log(_classString,
        '_batchProcessingBatch processing complete. Batches=${batches.length} Operations=$totalOperations',
        indent: true);
  }

  Future<void> _deleteDocsBatch({
    required String collection,
    String? sortingField, // if field is null, uses FieldPath.documentId
    String? minDocId,
    String? maxDocId,
    Query Function(Query)? filter,
  }) async {
    MyLog.log(_classString, '_deleteDocsBatch $collection: fromDate=$minDocId, toDate=$maxDocId');

    Query query = _getQuery(
        pathSegments: [collection],
        descending: false,
        sortingField: sortingField,
        minDocId: minDocId,
        maxDocId: maxDocId,
        filter: filter);

    final querySnapshot = await query.get();
    await _batchProcessing(
        querySnapshot: querySnapshot,
        processDocument: (WriteBatch batch, DocumentSnapshot docSnapshot) async {
          MyLog.log(_classString, '_deleteDocsBatch $collection=$collection', level: Level.FINE, indent: true);
          batch.delete(docSnapshot.reference);
        });
  }

  /// TODO: delete user from all matches and results
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
      throw MyException('Error al eliminar el usuario $myUser', e: e, level: Level.SEVERE);
    }
  }

  Future<void> deleteGameResult(GameResult result) async {
    MyLog.log(_classString, 'deleteResult deleting result $result');

    try {
      // delete the result
      await _instance.collection(GameResultFs.results.name).doc(result.id.resultId).delete();
      // delete the userMatchResults
      await deleteUserMatchResultBatch(resultId: result.id.resultId);
    } catch (e) {
      MyLog.log(_classString, 'deleteResult error when deleting',
          myCustomObject: result, level: Level.SEVERE, indent: true);
      throw MyException('Error al eliminar el resultado $result', e: e, level: Level.SEVERE);
    }
  }

  Future<void> deleteUserMatchResultTillDateBatch({String? maxMatchId}) async => await _deleteDocsBatch(
      collection: UserMatchResultFs.userMatchResult.name,
      sortingField: UserMatchResultFs.matchId.name,
      filter: (query) {
        if (maxMatchId != null) query = query.where(UserMatchResultFs.matchId.name, isLessThanOrEqualTo: maxMatchId);
        return query;
      });

  Future<void> deleteUserMatchResultBatch({String? userId, String? matchId, String? resultId}) async =>
      await _deleteDocsBatch(
          collection: UserMatchResultFs.userMatchResult.name,
          filter: (query) {
            if (userId != null) query = query.where(UserMatchResultFs.userId.name, isEqualTo: userId);
            if (matchId != null) query = query.where(UserMatchResultFs.matchId.name, isEqualTo: matchId);
            if (resultId != null) query = query.where(UserMatchResultFs.resultId.name, isEqualTo: resultId);
            return query;
          });

  Future<void> deleteGameResultsTillDateBatch({String? maxMatchId}) async => await _deleteDocsBatch(
      collection: GameResultFs.results.name,
      sortingField: GameResultFs.matchId.name,
      filter: (query) {
        if (maxMatchId != null) query = query.where(GameResultFs.matchId.name, isLessThanOrEqualTo: maxMatchId);
        return query;
      });

  Future<void> deleteDocsBatch({required String collection, String? minDocId, String? maxDocId}) async =>
      await _deleteDocsBatch(collection: collection, sortingField: null, minDocId: minDocId, maxDocId: maxDocId);
}

mixin _GetStream implements _Basic {
  Stream<List<T>>? _getStream<T>({
    required List<String> pathSegments, // List of collection/doc identifiers
    required T Function(Map<String, dynamic>, [AppState? appState]) fromJson,
    Date? fromDate,
    Date? toDate,
    AppState? appState,
    bool descending = false,
    Query Function(Query)? filter,
  }) {
    MyLog.log(_classString, 'getStream pathSegments=${pathSegments.join('/')}, filter=$filter');

    try {
      Query query = _getQuery(
        pathSegments: pathSegments,
        descending: descending,
        minDocId: fromDate?.toYyyyMmDd(),
        maxDocId: toDate?.toYyyyMmDd(),
        filter: filter,
      );

      return query.snapshots().transform(_transformer(fromJson, appState));
    } catch (e) {
      MyLog.log(_classString, 'getStream ERROR pathSegments=${pathSegments.join('/')}',
          exception: e, level: Level.SEVERE, indent: true);
      throw MyException('Error al obtener los streams ${pathSegments.join('/')}', e: e, level: Level.SEVERE);
    }
  }

  // stream of messages registered
  Stream<List<RegisterModel>>? getRegisterStream(int fromDaysAgo) => _getStream(
        pathSegments: [RegisterFs.register.name],
        fromJson: (json, [AppState? appState]) => RegisterModel.fromJson(json),
        fromDate: Date.now().subtract(Duration(days: fromDaysAgo)),
      );

  // stream of users
  Stream<List<MyUser>>? getUsersStream() => _getStream(
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

    return _getStream(
      pathSegments: [MatchFs.matches.name],
      fromJson: (json, [AppState? optionalAppState]) => MyMatch.fromJson(json, appState),
      fromDate: fromDate,
      toDate: toDate,
      appState: appState,
      filter: onlyOpenMatches ? (query) => query.where('isOpen', isEqualTo: true) : null,
      descending: descending,
    );
  }

  Stream<List<GameResult>>? getGameResultsStream({
    required AppState appState,
    required String matchId,
  }) {
    MyLog.log(_classString, 'getResultsStream matchId=$matchId');

    return _getStream(
      pathSegments: [GameResultFs.results.name],
      fromJson: (json, [AppState? optionalAppState]) => GameResult.fromJson(json, appState),
      appState: appState,
      filter: (query) => query.where(GameResultFs.matchId.name, isEqualTo: matchId),
    );
  }
}

/// Firestore helpers
class FbHelpers with _GetObject, _GetStream, _GetObjects, _UpdateObject, _DeleteObject, _Basic {
  static final FbHelpers _singleton = FbHelpers._internal();

  factory FbHelpers() => _singleton;

  FbHelpers._internal() {
    MyLog.log(_classString, 'FbHelpers created', level: Level.FINE);
  }

  StreamSubscription? _usersListener;
  StreamSubscription? _paramListener;

  Future<bool> doesDocExist({required String collection, required String doc}) async =>
      await _instance.collection(collection).doc(doc).get().then((doc) => doc.exists);

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
          throw MyException('Error de escucha. No se han podido cargar los parametros del sistema.\n$error',
              level: Level.SEVERE);
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
          throw MyException('Error de escucha. No se han podido cargar los usuarios del sistema',
              e: error, level: Level.SEVERE);
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
          throw MyException('Error en la base de datos de usuarios', e: e, level: Level.SEVERE);
        }
      } else {
        MyLog.log(_classString, '_downloadChangedUsers ERROR data null', level: Level.WARNING, indent: true);
      }
    }
  }

  /// return false if existed, true if created
  Future<bool> createMatchIfNotExists({required MyMatch match, required AppState appState}) async {
    bool exists = await doesDocExist(collection: MatchFs.matches.name, doc: match.id.toYyyyMmDd());
    if (exists) return false;

    MyLog.log(_classString, 'createMatchIfNotExists creating exist=$exists date=${match.id}');
    await _updateObject(
      fields: match.toJson(core: true, matchPlayers: false),
      pathSegments: [MatchFs.matches.name, match.id.toYyyyMmDd()],
      forceSet: false, // false: merges the fields, true:replaces the old object if exists
    );
    // create new registers in UserMatchRResults
    for (MyUser player in match.players) {
      MyLog.log(_classString, 'createMatchIfNotExists adding user=$player to match', indent: true );
      await addPlayerToMatch(matchId: match.id, player: player, appState: appState);
    }
    return true;
  }

  /// add a game result to the results collection
  /// add the result to the userMatchResult collection
  Future<void> createGameResult({required GameResult result}) async {
    // add the result to the results collection
    await _updateObject(
      fields: result.toJson(),
      pathSegments: [GameResultFs.results.name, result.id.resultId],
      forceSet: false, // false: merges the fields, true:replaces the old object if exists
    );
    // add the result to the userMatchResult collection
    await addUserMatchResult(
        userId: result.teamA!.player1.id, matchId: result.id.matchId, resultId: result.id.resultId);
    await addUserMatchResult(
        userId: result.teamA!.player2.id, matchId: result.id.matchId, resultId: result.id.resultId);
    await addUserMatchResult(
        userId: result.teamB!.player1.id, matchId: result.id.matchId, resultId: result.id.resultId);
    await addUserMatchResult(
        userId: result.teamB!.player2.id, matchId: result.id.matchId, resultId: result.id.resultId);
  }

  /// add Object with a new automatic Id
  Future<DocumentReference> _addObject({
    required Map<String, dynamic> fields,
    required List<String> pathSegments, // List of collection/doc identifiers
  }) async {
    MyLog.log(_classString, 'addObject ${pathSegments.join('/')}, ', indent: true);

    try {
      CollectionReference collectionReference = _getCollectionRef(pathSegments: pathSegments);
      DocumentReference documentReference = await collectionReference.add(fields);

      MyLog.log(_classString, 'addObject ${pathSegments.join('/')}, success', indent: true);
      return documentReference;
    } catch (onError) {
      MyLog.log(_classString, 'addObject ${pathSegments.join('/')} error:', exception: onError, level: Level.SEVERE);
      throw MyException('Error al actualizar ${pathSegments.join('/')}', e: onError, level: Level.SEVERE);
    }
  }

  Future<DocumentReference> addUserMatchResult({
    required String userId,
    required String matchId,
    String? resultId,
  }) async {
    MyLog.log(_classString, 'addUserMatchResult adding user=$userId to match=$matchId and result=$resultId');
    return await _addObject(
        fields: UserMatchResult(userId: userId, matchId: matchId, resultId: resultId).toJson(),
        pathSegments: [UserMatchResultFs.userMatchResult.name]);
  }

  /// return match with the position of inserted user
  /// Add the player to the Match's list of players.
  ///     Create a UserMatchResult entry linking the User and the Match.
  ///     Set the User's isActive status to true.
  Future<Map<MyMatch, int>> addPlayerToMatch({
    required Date matchId,
    required MyUser player,
    required AppState appState,
    int position = -1,
  }) async {
    MyLog.log(_classString, 'addPlayerToMatch adding user $player to $matchId position $position');
    DocumentReference matchDocReference = _instance.collection(MatchFs.matches.name).doc(matchId.toYyyyMmDd());

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
        // new match
        myMatch = MyMatch(id: matchId, comment: appState.getParamValue(ParametersEnum.defaultCommentText));
        MyLog.log(_classString, 'addPlayerToMatch NEW match ', indent: true);
      }

      // add player to memory match
      int posInserted = myMatch.insertPlayer(player, position: position);
      // exception caught by catchError
      if (posInserted == -1) {
        MyLog.log(_classString, 'Error: el jugador $player ya estaba en el partido.', indent: true, level: Level.WARNING);
        throw MyException('Error: el jugador $player ya estaba en el partido.', level: Level.WARNING);
      }
      MyLog.log(_classString, 'addPlayerToMatch player inserted match = ', myCustomObject: myMatch, indent: true);

      // create new UserMatchResult
      UserMatchResult userMatchResult = UserMatchResult(userId: player.id, matchId: myMatch.id.toYyyyMmDd());

      // add/update match to firebase
      transaction.set(
        matchDocReference,
        myMatch.toJson(core: false, matchPlayers: true),
        SetOptions(merge: true),
      );
      // add/update userMatchResult to firebase
      DocumentReference userMatchResultDocReference =
          _instance.collection(UserMatchResultFs.userMatchResult.name).doc(); // new doc
      transaction.set(
        userMatchResultDocReference,
        userMatchResult.toJson(),
        SetOptions(merge: true),
      );
      // update players isActive toggle
      if (player.isActive == false) {
        // update user in firebase
        player.isActive = true;
        transaction.set(
            _instance.collection(UserFs.users.name).doc(player.id), player.toJson(), SetOptions(merge: true));
      }

      // Return the map with MyMatch and player position
      return {myMatch: posInserted};
    }).catchError((e) {
      MyLog.log(_classString, 'addPlayerToMatch error adding $player to match $matchId',
          exception: e, level: Level.WARNING, indent: true);
      throw MyException('Error al añadir el jugador $player al partido $matchId', e: e, level: Level.WARNING);
    });
  }

  /// return match
  /// Remove the player from the Match's list of players.
  ///     Remove the UserMatchResult entry linking the User and the Match.
  ///     Crucially: Remove any UserMatchResult entries that link the User to any GameResult within that Match.
  ///     This ensures that orphaned game results are not left behind.
  ///     Check if the User is associated with any other Match in the UserMatchResult table.
  ///     If not, set the User's isActive status to false.
  ///
  ///     ERROR: if the player has a result published, an exception is thrown
  ///
  Future<MyMatch> deletePlayerFromMatch({
    required Date matchId,
    required MyUser player,
    required AppState appState,
  }) async {
    MyLog.log(_classString, 'deletePlayerFromMatch deleting user $player from $matchId');
    DocumentReference matchDocReference = _instance.collection(MatchFs.matches.name).doc(matchId.toYyyyMmDd());

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
        MyLog.log(_classString, 'deletePlayerFromMatch match doesnt exist $matchId', level: Level.SEVERE, indent: true);
        throw MyException('Error: no existe el partido $matchId', level: Level.SEVERE);
      }

      // delete player in match
      bool removed = myMatch.removePlayer(player);
      // exception caught by catchError
      if (!removed) throw MyException('Error: el jugador ${player.id} no estaba en el partido.', level: Level.FINE);
      MyLog.log(_classString, 'deletePlayerFromMatch $player removed match = ', myCustomObject: myMatch, indent: true);

      // update match in firebase
      transaction.set(
        matchDocReference,
        myMatch.toJson(core: false, matchPlayers: true),
        SetOptions(merge: true),
      );

      // remove match from userMatchResult
      List<String> userMatchResultIds =
          await getUserMatchResultIds(userId: player.id, matchId: myMatch.id.toYyyyMmDd());
      // remove userMatchesResults  from firebase
      for (final userMatchResultId in userMatchResultIds) {
        // get userMatchResult
        DocumentReference userMatchResultDocReference =
            _getDocRef(pathSegments: [UserMatchResultFs.userMatchResult.name, userMatchResultId]);
        UserMatchResult? userMatchResult = await getUserMatchResult(userMatchResultId: userMatchResultId);

        if (userMatchResult != null && userMatchResult.resultId != null) {
          // ERROR. This player has a result published
          MyLog.log(_classString, 'deletePlayerFromMatch error deleting $player from match $matchId',
              level: Level.WARNING, indent: true);
          throw MyException('Error: el jugador ${player.id} YA tiene un resultado publicado.', level: Level.WARNING);
        }

        transaction.delete(userMatchResultDocReference);
      }

      // is player still active?
      // TODO: I dont know how to do it in the transaction
      int playersCount = await countAllMatchesWithPlayer(playerId: player.id);
      if (playersCount == 1) {
        // this player is only in one match
        // which is about to be signed off
        DocumentReference userDocReference = _instance.collection(UserFs.users.name).doc(player.id);
        player.isActive = false;
        transaction.set(userDocReference, player.toJson(), SetOptions(merge: true));
      }

      return myMatch;
    }).catchError((onError) {
      // catches all the errors thrown by then and deletePlayerFromMatch
      MyLog.log(_classString, 'deletePlayerFromMatch error deleting $player from match $matchId',
          exception: onError, level: Level.SEVERE, indent: true);
      throw MyException('Error al eliminar el jugador $player del partido $matchId', e: onError, level: Level.SEVERE);
    });
  }

  /// returns the count of all matches containing a player
  /// uses the transaction if not null
  Future<int> countAllMatchesWithPlayer({
    required String playerId,
    Date? fromDate,
    Date? toDate,
  }) async {
    MyLog.log(_classString, 'countAllMatchesWithPlayer = $playerId fromDate=$fromDate toDate=$toDate',
        level: Level.FINE);

    try {
      Query query = _getQuery(
        pathSegments: [MatchFs.matches.name],
        descending: false,
        minDocId: fromDate?.toYyyyMmDd(),
        maxDocId: toDate?.toYyyyMmDd(),
        filter: (query) => query.where(MatchFs.players.name, arrayContains: playerId),
      );

      AggregateQuerySnapshot querySnapshot = await query.count().get();
      int? count = querySnapshot.count;
      MyLog.log(_classString, 'countAllMatchesWithPlayer $playerId count=$count', indent: true);
      return count ?? 0;
    } catch (e) {
      MyLog.log(_classString, 'countAllMatchesWithPlayer  $playerId ERROR ',
          exception: e, level: Level.SEVERE, indent: true);
      throw MyException('Error al obtener el número de partidos del jugador $playerId', e: e, level: Level.SEVERE);
    }
  }

  /// set all users ranking to newRanking
  /// make all users inactive
  Future<void> resetUsersBatch({required int newRanking}) async {
    MyLog.log(_classString, 'resetUsersBatch = $newRanking');
    final usersCollection = FirebaseFirestore.instance.collection(UserFs.users.name);

    // 1. Retrieve user documents
    final querySnapshot = await usersCollection.get();

    await _batchProcessing(
        querySnapshot: querySnapshot,
        processDocument: (WriteBatch batch, DocumentSnapshot docSnapshot) async {
          MyLog.log(_classString, 'resetUsersBatch Processing user: ${docSnapshot.id}',
              level: Level.FINE, indent: true);
          int numberOfMatches = await countAllMatchesWithPlayer(playerId: docSnapshot.id);
          bool isActive = numberOfMatches > 0;
          batch.update(docSnapshot.reference, {UserFs.rankingPos.name: newRanking, UserFs.isActive.name: isActive});
        });
  }

  Future saveAllUsersToHistoric() async {
    MyLog.log(_classString, 'saveAllUsersToHistoric');
    List<MyUser> allUsers = await getAllUsers();

    Historic historic = Historic.fromUsers(id: Date.now(), users: allUsers);
    await updateHistoric(historic: historic);
  }
}
