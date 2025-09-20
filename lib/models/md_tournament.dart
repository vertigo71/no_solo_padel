// Imports
import 'package:simple_logger/simple_logger.dart';

import 'md_date.dart';
import 'md_debug.dart';

final String _classString = '<md> Tournament'.toLowerCase();

enum TournamentFs { parameters, tournament, initialDate, endDate, rankingType }

enum RankingType { score, league }

class Tournament {
  final Date initialDate;
  final Date? endDate;
  final RankingType rankingType;

  Tournament({
    required this.initialDate,
    required this.rankingType,
    this.endDate,
  }){
    MyLog.log(_classString, 'Building', level: Level.FINE);
  }

  Tournament copyWith({
    Date? initialDate,
    Date? endDate,
    RankingType? rankingType,
  }) {

    return Tournament(
      initialDate: initialDate ?? this.initialDate,
      endDate: endDate ?? this.endDate,
      rankingType: rankingType ?? this.rankingType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tournament &&
        initialDate == other.initialDate &&
        endDate == other.endDate &&
        rankingType == other.rankingType;
  }

  @override
  int get hashCode => Object.hash(initialDate, endDate, rankingType);

  // Creates a Tournament object from a JSON map.
  factory Tournament.fromJson(Map<String, dynamic> json) {
    if (json[TournamentFs.initialDate.name] is! String || json[TournamentFs.rankingType.name] == null) {
      throw const FormatException('Missing or invalid required fields in JSON.');
    }

    final initialDate = Date.parse(json[TournamentFs.initialDate.name] as String) ?? Date.now();
    final endDate =
        json[TournamentFs.endDate.name] is String ? Date.parse(json[TournamentFs.endDate.name] as String) : null;

    // Get the integer index from the JSON
    final rankingTypeIndex = json[TournamentFs.rankingType.name] as int;

    // Use the index to get the enum value
    final rankingType = RankingType.values.length > rankingTypeIndex
        ? RankingType.values[rankingTypeIndex]
        : RankingType.score; // Fallback to a default value

    return Tournament(
      initialDate: initialDate,
      endDate: endDate,
      rankingType: rankingType,
    );
  }

  // Converts the Tournament object to a JSON map, saving the enum's index.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      TournamentFs.initialDate.name: initialDate.toYyyyMmDd(),
      // Save the enum's index instead of its name
      TournamentFs.rankingType.name: rankingType.index,
    };
    if (endDate != null) {
      json[TournamentFs.endDate.name] = endDate!.toYyyyMmDd();
    }
    return json;
  }
}
