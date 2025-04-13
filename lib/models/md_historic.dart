import 'package:simple_logger/simple_logger.dart';
import 'package:collection/collection.dart'; // For deep comparison of lists
import 'md_date.dart';
import 'md_user.dart';

final String _classString = '<md> Historic'.toLowerCase();

// result fields in Firestore
enum HistoricFs { historic, id, users }

class Historic {
  Date id;
  final List<MyUser> _users = [];

  Historic(this.id, [List<MyUser>? users]) {
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
      Date.parse(json['id']) ?? Date.now(), // Assuming 'id' is a String representation of Date
      // You might need to adjust the key based on your actual JSON structure
    ).._users.addAll((json['users'] as List<dynamic>?)
            ?.map((userJson) => MyUser.fromJson(userJson as Map<String, dynamic>))
            .toList() ??
        []);
    // Assuming 'users' is a List of MyUser objects represented as JSON
  }

  // ToJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id.toIso8601String(), // Or your preferred Date format
      'users': _users.map((user) => user.toJson()).toList(),
    };
  }
}
