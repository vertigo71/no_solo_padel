import 'package:collection/collection.dart';
import 'package:simple_logger/simple_logger.dart';
import 'md_date.dart';
import 'md_user.dart';
import 'md_debug.dart';

final String _classString = '<md> Historic'.toLowerCase();

// result fields in Firestore
enum HistoricFs { historic, id, users }

class Historic {
  Date id;
  final List<MyUser> _users = [];

  Historic(this.id, [List<MyUser>? users]) {
    MyLog.log(_classString, 'constructor', level: Level.FINE);
    if (users != null) _users.addAll(users);
  }

  // CopyFrom method (updates the existing object)
  void copyFrom(Historic other) {
    id = other.id;
    _users.clear();
    _users.addAll(other._users.map((user) => user.copyWith()));
  }

  // CopyWith method (creates a new object)
  Historic copyWith({
    Date? id,
    List<MyUser>? users,
  }) {
    return Historic(
      id ?? this.id,
    ).._users.addAll(users?.map((user) => user.copyWith()).toList() ?? _users.map((user) => user.copyWith()).toList());
  }

  // Operator ==
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Historic && id == other.id && const DeepCollectionEquality().equals(_users, other._users);
  }

  @override
  int get hashCode => Object.hash(id, const DeepCollectionEquality().hash(_users));

  // FromJson method
  factory Historic.fromJson(Map<String, dynamic> json) {
    return Historic(
      Date.parse(json[HistoricFs.id.name]) ?? Date.now(),
    ).._users.addAll((json[HistoricFs.users.name] as List<dynamic>?)
            ?.map((userJson) => MyUser.fromJson(userJson as Map<String, dynamic>))
            .toList() ??
        []);
  }

  // ToJson method
  Map<String, dynamic> toJson() {
    return {
      HistoricFs.id.name: id.toYyyyMMdd(),
      HistoricFs.users.name: _users.map((user) => user.toJson()).toList(),
    };
  }
}
