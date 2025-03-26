import 'package:flutter/material.dart';

import '../../../models/debug.dart';

final String _classString = 'RankingPanel'.toUpperCase();

class RankingPanel extends StatelessWidget {
  const RankingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building Form for match');

    return const Center(child: Text('Ranking Sorting'));
  }
}
