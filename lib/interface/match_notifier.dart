import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/debug.dart';
import '../models/match_model.dart';
import 'director.dart';

final String _classString = 'MatchNotifier'.toUpperCase();

/// holds a Match. If a change is made propagates to anyone who is listening
/// listens to firebase if the match changes
class MatchNotifier with ChangeNotifier {
  MyMatch _match;
  final Director _director;
  StreamSubscription? _matchSubscription;

  MatchNotifier(this._match, this._director) {
    MyLog.log(_classString, 'Building $_match');
    _init();
  }

  MyMatch get match => _match;

  /// ONLY to use if the match is updated with a new one
  /// which matchId is different
  /// update the match in the notifier
  /// notify any listener that match has changed
  ///
  /// Not to call if the match has been updated
  /// with the same matchId
  /// to the Firestore
  /// in this case, _notifyIfChanged will do the updating
  ///
  void updateMatch(MyMatch newMatch) {
    MyLog.log(_classString, 'updateMatch: $newMatch');
    if (_match.id != newMatch.id) {
      MyLog.log(_classString, 'updateMatch: different ids old=$_match', level: Level.INFO);
      _match = newMatch;
      // redo the listener
      _matchSubscription?.cancel();
      _init();
    } else {
      _match = newMatch;
    }
    notifyListeners(); // Notify listeners about the change
  }

  void _init() {
    _matchSubscription = _director.fsHelpers.listenToMatch(
      matchId: _match.id,
      appState: _director.appState,
      matchFunction: _notifyIfChanged,
    );
  }

  void _notifyIfChanged(MyMatch newMatch) {
    if (_match != newMatch) {
      MyLog.log(_classString, 'Match updated from Firestore: $newMatch');
      _match = newMatch;
      notifyListeners(); // Notify listeners about the change
    }
  }

  @override
  void dispose() {
    MyLog.log(_classString, 'Disposed = $_match');
    _matchSubscription?.cancel();
    super.dispose();
  }
}
