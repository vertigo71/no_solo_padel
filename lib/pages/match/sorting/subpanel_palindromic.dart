import 'package:flutter/material.dart';

import '../../../models/debug.dart';

final String _classString = 'PalindromicPanel'.toUpperCase();

class PalindromicPanel extends StatelessWidget {
  const PalindromicPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building Form for match');

    return const Center(child: Text('Palindromic Sorting'));
  }
}