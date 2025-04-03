import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../models/debug.dart';

/// Class name identifier for logging
final String _classString = 'RankingParamPanel'.toUpperCase();

/// The main widget for the ranking parameters panel
class RankingParamPanel extends StatefulWidget {
  const RankingParamPanel({super.key});

  @override
  RankingParamPanelState createState() => RankingParamPanelState();
}

class RankingParamPanelState extends State<RankingParamPanel> {
  double _currentValue = 20;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState', level: Level.FINE);

    // Retrieve instances from Provider
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Value: ${_currentValue.toStringAsFixed(0)}'),
            Slider(
              value: _currentValue,
              min: 0,
              max: 100,

              label: _currentValue.round().toString(),
              // Optional: display value
              onChanged: (double value) {
                setState(() {
                  _currentValue = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
