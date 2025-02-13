import 'dart:async';
import 'package:flutter/material.dart';

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

  /// update the match in the notifier
  /// notify any listener that match has changed
  ///
  /// Not to call if the match has been updated
  /// to the Firestore
  /// in this case, _notifyIfChanged will do the updating
  ///
  void updateMatch(MyMatch newMatch) {
    _match = newMatch;
    notifyListeners(); // Notify listeners about the change
  }

  void _init() {
    _matchSubscription = _director.fsHelpers.listenToMatch(
      date: _match.date,
      appState: _director.appState,
      matchFunction: _notifyIfChanged,
    );
  }

  void _notifyIfChanged(MyMatch newMatch) {
    if (_match != newMatch) {
      MyLog.log(_classString, 'Match updated from Firestore: $newMatch');
      updateMatch(newMatch);
    }
  }

  @override
  void dispose() {
    MyLog.log(_classString, 'Disposed = $_match');
    _matchSubscription?.cancel();
    super.dispose();
  }
}
