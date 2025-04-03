import 'package:diacritic/diacritic.dart';
import 'package:simple_logger/simple_logger.dart';
import 'dart:math';

import '../models/debug.dart';

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

/// Calculates the points awarded to the WINNING team based on ranking difference,
/// with a specific ranking difference threshold for half-point adjustment.
/// Looser gets 0 points
///
/// This function determines the number of points a team earns per game, taking into account:
/// - The minimum points awarded (`step`).
/// - The range of possible points (`range`).
/// - The ranking difference threshold for half-point adjustment (`rankingDiffToHalf`).
/// - The absolute difference in team rankings (`pointDiff`).
/// - Whether the favorite team won (`isFavorite`).
///
/// The calculation uses a fraction that's derived from the ranking difference and a scaling factor (`k`),
/// which is then used to adjust the points awarded within the given range. The scaling factor `k` is
/// calculated as `1.0 / rankingDiffToHalf`, creating a direct relationship between the ranking difference
/// and the adjustment of points.
///
/// If the favorite team wins, the awarded points are calculated as `step + range * fraction`.
/// If the underdog wins, the awarded points are calculated as `step + range - range * fraction`.
///
/// Logs the input parameters and the calculated intermediate fraction and result for debugging purposes.
///
/// Parameters:
///   - `step`: The minimum number of points awarded (integer).
///   - `range`: The range of possible points to be awarded (integer).
///   - `rankingDiffToHalf`: The ranking difference at which the point adjustment is halved (integer).
///   - `pointDiff`: The absolute difference in team rankings (integer).
///   - `isFavorite`: A boolean indicating whether the favorite team won (true) or not (false).
///
/// Returns:
///   The calculated points awarded to the team (double).
///
/// Examples:
///   1. Ranking Difference = 0:
///      If `rankingDiffToHalf` is 3000, `step` is 20, and `range` is 60, and the ranking difference is 0,
///      regardless of who wins, each team gets 20 + 60 / 2 = 50 points.
///
///   2. Ranking Difference = 3000 (equal to `rankingDiffToHalf`):
///      If `rankingDiffToHalf` is 3000, `step` is 20, and `range` is 60,
///      and Team A's ranking is 3000 points higher than Team B's:
///        - If Team A wins, it gets 20 + (60 / 2) / 2 = 35 points.
///        - If Team B wins, it gets 20 + 60 - (60 / 2) / 2 = 65 points.
///
double pointsPerGame(int step, int range, int rankingDiffToHalf, int pointDiff, bool isFavorite) {
  MyLog.log(_classString, 'pointsPerGame ', level: Level.FINE, indent: true);

  // calculate k, the scaling factor, based on rankingDiffToHalf.
  // with factor 1.0, rankingDiffToHalf gets its meaning
  double k = 1.0 * pointDiff.abs() / rankingDiffToHalf;

  // Calculate the fraction based on ranking difference and the scaling factor k.
  final double fraction = (1 + k) / (1 + exp(2 * k));

  late double result;

  // Determine points based on whether the favorite team won.
  if (isFavorite) {
    result = step + range * fraction; // Favorite team wins
  } else {
    result = step + range - range * fraction; // Underdog wins
  }

  MyLog.log(
      _classString,
      'pointsPerGame: s=$step r=$range half=$rankingDiffToHalf d=$pointDiff favorite=$isFavorite '
      'fraction=$fraction, result=$result',
      indent: true);

  return result;
}

/// Calculates and returns the points awarded to each team in a game based on their scores and rankings.
///
/// This function determines the points earned by Team A and Team B, considering the score difference,
/// ranking difference, and the parameters that influence point distribution.
///
/// Parameters:
///   - `step`: The minimum number of points awarded to a team (integer).
///   - `range`: The range of possible points to be awarded (integer).
///   - `rankingDiffToHalf`: The ranking difference at which the point adjustment is halved (integer).
///   - `rankingA`: The ranking of Team A (integer).
///   - `rankingB`: The ranking of Team B (integer).
///   - `scoreA`: The score of Team A (integer).
///   - `scoreB`: The score of Team B (integer).
///
/// Returns:
///   A `List<int>` containing two elements:
///     - The points awarded to Team A.
///     - The points awarded to Team B.
///
/// Calculation Logic:
///   1. Determines the score difference (`scoreDiff`) and ranking difference (`rankingDiff`) between Team A and Team B.
///   2. Identifies the favorite team (`favoriteA`) based on the ranking difference.
///   3. Calculates points based on the game's outcome:
///     - If Team A wins (`scoreDiff > 0`), Team A gets points calculated by `scoreDiff * pointsPerGame(...)`, and Team B gets 0.
///     - If Team B wins (`scoreDiff < 0`), Team B gets points calculated by `abs(scoreDiff) * pointsPerGame(...)`, and Team A gets 0.
///     - If it's a tie (`scoreDiff == 0`):
///       - If rankings are equal (`rankingDiff == 0`), both teams get `step` points.
///       - If Team A is the favorite (`favoriteA`), Team B gets `step` points, and Team A gets 0.
///       - If Team B is the favorite, Team A gets `step` points, and Team B gets 0.
///
/// Note:
///   - The `pointsPerGame` function is used to calculate points based on ranking difference and other parameters.
///   - The `MyLog.log` call is for debugging and can be removed in production code.
///
/// Example:
///   If Team A wins by 2 points and is the favorite, and `step` is 20, the function calculates the points
///   awarded to Team A based on the `pointsPerGame` function and returns a list like `[calculatedPoints, 0]`.
///
///   List(int) points = calculatePoints(20, 60, 3000, 5000, 4000, 2, 0);
///   // points will be calculated based on the formula.
///
///   If it's a tie and the rankings are equal, the function returns `[20, 20]`.
///
///   List(int) points = calculatePoints(20, 60, 3000, 4000, 4000, 0, 0);
///   // points will be [20, 20].
///
///   If it is a tie and Team B is the favorite, then the function returns [20,0].
///
///   List(int) points = calculatePoints(20, 60, 3000, 4000, 6000, 0, 0);
///   // points will be [20,0].
List<int> calculatePoints(
    int step, int range, int rankingDiffToHalf, int rankingA, int rankingB, int scoreA, int scoreB) {
  MyLog.log(_classString,
      'calculatePoints s=$step r=$range half=$rankingDiffToHalf a=$rankingA b=$rankingB aS=$scoreA bS=$scoreB',
      indent: true, level: Level.FINE);

  final int scoreDifference = scoreA - scoreB; // teamA - teamB
  final int rankingDifference = rankingA - rankingB; // teamA - teamB
  final bool teamAIsFavorite = rankingDifference > 0;

  // true if a and b are equal
  bool nxor(bool a, bool b) => a == b;

  double calculateTeamPoints(bool isTeamA) {
    if (scoreDifference == 0 && rankingDifference == 0) {
      // tie in score and ranking. Share points
      return step.toDouble();
    }

    if (scoreDifference == 0) {
      // (NXOR) tie in score. Lower ranking team wins
      return nxor(teamAIsFavorite, isTeamA) ? 0 : step.toDouble() + range.toDouble() / 2;
    }

    if (nxor(isTeamA, scoreDifference.isNegative)) {
      // team has lost
      return 0;
    }

    // team has won
    return scoreDifference.abs() *
        pointsPerGame(step, range, rankingDiffToHalf, rankingDifference, nxor(isTeamA, teamAIsFavorite));
  }

  return [
    calculateTeamPoints(true).round(),
    calculateTeamPoints(false).round(),
  ];
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

String lowCaseNoDiacritics(String str) => removeDiacritics(str.toLowerCase());
