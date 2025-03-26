import 'package:flutter/material.dart';

import '../../../models/debug.dart';

final String _classString = 'UpsideDownPanel'.toUpperCase();

class UpsideDownPanel extends StatelessWidget {
  const UpsideDownPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building Form for match');

    return const Center(child: Text('Upside Down Sorting'));
  }
}
