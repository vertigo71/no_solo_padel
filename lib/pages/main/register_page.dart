import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/register_model.dart';
import '../../models/parameter_model.dart';

final String _classString = 'RegisterPage'.toUpperCase();

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    AppState appState = context.read<AppState>();
    FbHelpers fbHelpers = context.read<Director>().fbHelpers;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream:
                  fbHelpers.getRegisterStream(appState.getIntParameterValue(ParametersEnum.registerDaysAgoToView) ?? 0),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error al acceder al registro: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData) {
                  List<RegisterModel> logs = snapshot.data as List<RegisterModel>;
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (BuildContext context, int index) => Card(
                      elevation: 6,
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          logs.elementAt(index).date.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          logs.elementAt(index).foldedString,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const Center(
                      child: Text(
                    'No hay datos',
                    style: TextStyle(fontSize: 24.0),
                  ));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
