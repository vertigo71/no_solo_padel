import 'package:flutter/material.dart';

import '../models/debug.dart';

final String _classString = 'LoggingPage'.toUpperCase();

class LoggingPage extends StatelessWidget {
  const LoggingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    return Scaffold(
      appBar: AppBar(title: const Text('Logging')),
      body: ListView.builder(
        itemCount: MyLog().logMsgList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(MyLog().logMsgList[index]),
          );
        },
      ),
    );
  }
}
