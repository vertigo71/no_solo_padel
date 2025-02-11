import 'package:flutter/material.dart';

import '../models/debug.dart';
import '../models/match_model.dart';

final String _classString = 'MatchNotifier'.toUpperCase();

/// holds a Match. If a change is made propagates to anyone who is listening
class MatchNotifier with ChangeNotifier {
  MatchNotifier(this._match) {
    // Initialize with the initial match
    MyLog.log(_classString, 'Building ');
  }

  MyMatch _match;

  MyMatch get match => _match;

  void updateMatch(MyMatch newMatch) {
    _match = newMatch;
    notifyListeners(); // Notify listeners about the change
  }
}
