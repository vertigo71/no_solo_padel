import 'package:collection/collection.dart';
import 'package:simple_logger/simple_logger.dart';
import 'md_date.dart';
import 'md_user.dart';
import 'md_debug.dart';

final String _classString = '<md> Historic'.toLowerCase();

// result fields in Firestore
enum HistoricFs { historic, id, usersRanking }

class Historic {
  Date id;
  final Map<String, int> _usersRanking = {};

  /// Constructor
  /// _usersRanking is a Map{String, int} where the key is the user id and the value is the ranking position
  /// user id must be different from HistoricFs.id.name
  Historic({required this.id, Map<String, int>? usersRanking}) {
    MyLog.log(_classString, 'constructor', level: Level.FINE);
    _usersRanking.addAll(usersRanking ?? {});
    if (_usersRanking.remove(HistoricFs.id.name) != null) {
      MyLog.log(_classString, 'user id found ${HistoricFs.id.name}', level: Level.WARNING);
    }
  }

  Historic.fromUsers({required this.id, List<MyUser>? users}) {
    MyLog.log(_classString, 'constructor fromUsers', level: Level.FINE);
    users?.forEach((user) {
      if (user.id != HistoricFs.id.name) {
        _usersRanking[user.id] = user.rankingPos;
      }
    });
  }

  // CopyFrom method (updates the existing object)
  void copyFrom(Historic other) {
    MyLog.log(_classString, 'copyFrom', level: Level.FINE);

    id = other.id;
    _usersRanking.clear();
    _usersRanking.addAll(other._usersRanking);
  }

  // CopyWith method (creates a new object)
  Historic copyWith({
    Date? id,
    Map<String, int>? usersRanking,
  }) {
    MyLog.log(_classString, 'copyWith', level: Level.FINE);

    return Historic(
      id: id ?? this.id,
      usersRanking: usersRanking ?? _usersRanking,
    );
  }

  // Operator ==
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Historic &&
        id == other.id &&
        const DeepCollectionEquality().equals(_usersRanking, other._usersRanking);
  }

  @override
  int get hashCode => Object.hash(id, const DeepCollectionEquality().hash(_usersRanking));

  factory Historic.fromJson(Map<String, dynamic> json) {
    MyLog.log(_classString, 'fromJson', level: Level.FINE);

    final id = Date.parse(json[HistoricFs.id.name]) ?? Date.now();

    final usersRanking = Map<String, int>.fromEntries(
      json.entries
          .where((entry) => entry.key != HistoricFs.id.name && entry.value is int)
          .map((entry) => MapEntry(entry.key, entry.value as int)),
    );

    return Historic(id: id, usersRanking: usersRanking);
  }

  Map<String, dynamic> toJson() {
    MyLog.log(_classString, 'toJson', level: Level.FINE);

    return {
      HistoricFs.id.name: id.toYyyyMmDd(),
      ..._usersRanking,
    };
  }
}
