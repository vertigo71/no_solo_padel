import 'dart:async';
import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';

import '../models/debug.dart';
import '../models/match_model.dart';
import 'director.dart';

final String _classString = '<st> MatchNotifier'.toLowerCase();

/// Holds a [MyMatch] object and provides change notifications.
/// Listens to Firestore for changes to the associated match.
class MatchNotifier with ChangeNotifier {
  /// The [MyMatch] object being managed by this notifier.
  MyMatch _match;

  /// A reference to the [Director] object, providing access to Firebase helpers and application state.
  final Director _director;

  /// A subscription to the Firestore stream for the associated match.
  /// Used to listen for real-time updates from Firestore.
  StreamSubscription? _matchSubscription;

  /// Constructs a [MatchNotifier] with the given [MyMatch] and [Director].
  /// Initializes the Firestore listener.
  MatchNotifier(this._match, this._director)  {
    MyLog.log(_classString, 'Constructor match = $_match');
    _createListener();
  }

  /// Returns the current [MyMatch] object.
  MyMatch get match => _match;

  /// Initializes the Firestore listener for the associated match.
  /// Listens for changes to the match document in Firestore.
  void _createListener() {
    MyLog.log(_classString, '_createListener: create _matchSubscription for match=$_match');

    _matchSubscription?.cancel();

    try {
      _matchSubscription = _director.fbHelpers.listenToMatch(
            matchId: _match.id,
            appState: _director.appState,
            matchFunction: _notifyIfChanged,
          );
    } catch (e) {
      MyLog.log(_classString, '_createListener ERROR listening to match ${_match.id}',
          exception: e, level: Level.SEVERE, indent: true);
      throw Exception('Error: No se ha podido crear el listener. '
          'Es posible que los partidos no se refresquen bien.\n${e.toString()}');
    }
  }

  /// Callback function called when the Firestore document for the associated match changes.
  /// Compares the new match data with the current [_match] and updates it if there are changes.
  /// Notifies listeners if the match has been updated from Firestore.
  void _notifyIfChanged(MyMatch newMatch) {
    MyLog.log(_classString, '_notifyIfChanged for match=${_match.id}');
    if (_match != newMatch) {
      MyLog.log(_classString, '_notifyIfChanged Match updated from Firestore: $newMatch', indent: true);
      _match = newMatch;
      notifyListeners(); // Notify listeners about the change
    }
  }


  /// Updates the [MyMatch] object with a new [MyMatch].
  /// If the new match has a different ID, it cancels the existing Firestore listener and creates a new one.
  /// Primarily intended for cases where the match ID changes (e.g., when replacing the match with a different one).
  /// Should not be used for updates from Firestore, as those are handled by [_notifyIfChanged].
  void updateMatch(MyMatch newMatch) {
    MyLog.log(_classString, 'updateMatch: $newMatch');
    if (_match.id != newMatch.id) {
      MyLog.log(_classString, 'updateMatch: different ids old=$_match', indent: true);
      _match = newMatch;
      // Redo the listener
      _createListener();
    } else {
      _match = newMatch;
    }
    notifyListeners(); // Notify listeners about the change
  }

  /// Disposes of the [MatchNotifier].
  /// Cancels the Firestore listener to prevent memory leaks.
  @override
  void dispose() {
    MyLog.log(_classString, 'Disposed = $_match');
    _matchSubscription?.cancel();
    super.dispose();
  }
}
