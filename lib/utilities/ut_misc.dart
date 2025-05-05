import 'package:diacritic/diacritic.dart';
import 'package:simple_logger/simple_logger.dart';
import 'dart:math';

import '../models/md_debug.dart';
import '../models/md_exception.dart';

final String _classString = 'Miscellaneous'.toUpperCase();

/// Generates a pseudo-random list of integers based on a given date and length.
///
/// This function produces a list of integers of length [numOfElements], where the order of
/// elements is determined by a pseudo-random sequence derived from the
/// milliseconds since epoch of the provided [dateSeed]. The generated sequence aims
/// to distribute the numbers 0 to [numOfElements] - 1 in a seemingly random order.
///
/// The process involves:
/// 1. Generating a base list using a sinusoidal function and the date's timestamp.
/// 2. Identifying numbers within the range 0 to [numOfElements] - 1 that are missing from the base list.
/// 3. Inserting the missing numbers into the base list at positions determined by
///    the existing elements in the base list, or at the beginning if the position
///    is out of bounds.
///
/// The use of the date's timestamp as a seed allows for reproducible sequences
/// given the same date, while providing different sequences for different dates.
///
/// [num]: The desired length of the generated list.
/// [date]: The date used to generate the pseudo-random sequence.
///
/// Returns: A list of integers of length [numOfElements] in a pseudo-random order.
///
List<int> getRandomList(int numOfElements, DateTime dateSeed) {
  MyLog.log(_classString, 'getRandomList', level: Level.FINE);
  int baseNum = dateSeed.millisecondsSinceEpoch;
  List<int> base =
      List<int>.generate(numOfElements, (index) => (baseNum * sin(baseNum + index)).floor() % numOfElements)
          .toSet()
          .toList();
  MyLog.log(_classString, 'getRandomList Base Sinus generated list $base', indent: true, level: Level.FINE);

  List<int> all = List<int>.generate(numOfElements, (int index) => numOfElements - index - 1);
  List<int> diff = all.where((element) => !base.contains(element)).toList();
  MyLog.log(_classString, 'getRandomList Missing numbers list $diff', indent: true, level: Level.FINE);

  // add missing numbers
  for (int i = 0; i < diff.length; i++) {
    if (base[i] <= base.length) {
      base.insert(base[i], diff[i]);
    } else {
      base.insert(0, diff[i]);
    }
  }
  MyLog.log(_classString, 'getRandomList Final order $base', indent: true, level: Level.FINE);

  return base;
}

/// return a String formed with the number and the according adverb
/// number = 1, singular = match, plural = matches => 1 match
/// number = 2, singular = car, plural = null => 2 cars
String singularOrPlural(int number, String singular, [String? plural]) {
  if (number == 1) return '1 $singular';
  return '$number ${plural ?? singular + (singular.toUpperCase() == singular ? 'S' : 's')}';
}

int boolToInt(bool value) => value ? 1 : 0;

bool intToBool(int value) => value == 0 ? false : true;

String boolToStr(bool value) => value.toString();

/// true if value != 0 or is 'true'
bool strToBool(String value) {
  int? intValue = int.tryParse(value);
  if (intValue != null) return intValue != 0;
  if (value == 'true') return true;
  return false;
}

// lowerCase, no diacritics
int compareToNoDiacritics(String a, String b) =>
    removeDiacritics(a.toLowerCase()).compareTo(removeDiacritics(b.toLowerCase()));

// true if a and b are not equal
bool xor(bool a, bool b) => a != b;

// true if a and b are equal
bool xnor(bool a, bool b) => a == b;

class RankingPoints {
  /// - The minimum points awarded
  int step;

  /// - The range of possible points
  int range;

  /// -  The ranking difference at which the point adjustment is halved
  int rankingDiffToHalf;

  /// Reward points added to the calculated result for both teams
  int freePoints;

  /// The pre-match ranking points of Team A.
  int rankingA;

  /// The pre-match ranking points of Team B.
  int rankingB;

  /// The score of Team A in the match.
  int scoreA;

  /// The score of Team B in the match.
  int scoreB;

  RankingPoints({
    required this.step,
    required this.range,
    required this.rankingDiffToHalf,
    required this.freePoints,
    required this.rankingA,
    required this.rankingB,
    required this.scoreA,
    required this.scoreB,
  });

  /// Calculates the change in ranking points for Team A and Team B after a match.
  /// Considers the score difference and the ranking difference between the teams.
  List<int> calculatePoints() {
    MyLog.log(_classString,
        'calculatePoints s=$step r=$range half=$rankingDiffToHalf a=$rankingA b=$rankingB aS=$scoreA bS=$scoreB',
        indent: true, level: Level.FINE);

    final int scoreDifference = scoreA - scoreB; // teamA - teamB
    final int rankingDifference = rankingA - rankingB; // teamA - teamB
    final bool teamAIsFavorite = rankingDifference > 0;
    final bool teamAWins = scoreDifference > 0;

    // add free points to the result
    List<int> addFreePoints(int result) => [freePoints + result, freePoints - result];

    if (scoreDifference == 0 && rankingDifference == 0) {
      // tie in score and ranking. Share points
      int result = step.toDouble().round();
      return [result + freePoints, result + freePoints];
    }

    if (scoreDifference == 0) {
      // Tie in score. Lower ranking team wins
      int winnerResult = (step.toDouble() + range.toDouble() / 2).round();
      return teamAIsFavorite ? addFreePoints(-winnerResult) : addFreePoints(winnerResult);
    }

    int winnerResult = (scoreDifference.abs() * _winnerPointsPerGame(xnor(teamAWins, teamAIsFavorite))).round();

    return teamAWins ? addFreePoints(winnerResult) : addFreePoints(-winnerResult);
  }

  /// Calculates the base number of points awarded to the winner based on the ranking difference
  /// and whether they were the favorite.
  double _winnerPointsPerGame(bool isFavorite) {
    int rankingDifference = (rankingA - rankingB).abs();

    // calculate k, the scaling factor, based on rankingDiffToHalf.
    // with factor 1.0, rankingDiffToHalf gets its meaning
    if (rankingDiffToHalf == 0) {
      MyLog.log(_classString, 'Error: el DR mitad es 0', level: Level.SEVERE, indent: true);
      throw MyException('Error: el DR mitad es 0', level: Level.SEVERE);
    }
    double k = 1.0 * rankingDifference / rankingDiffToHalf;

    // Calculate the fraction based on ranking difference and the scaling factor k.
    final double fraction = (1 + k) / (1 + exp(2 * k));

    late double result;

    // Determine points based on whether the favorite team won.
    if (isFavorite) {
      result = step + range * fraction; // Favorite team wins
    } else {
      result = step + range * (1 - fraction); // Underdog wins
    }

    MyLog.log(
        _classString,
        'pointsPerGame: s=$step r=$range half=$rankingDiffToHalf d=$rankingDifference favorite=$isFavorite '
        'fraction=$fraction, result=$result',
        indent: true);

    return result;
  }
}
