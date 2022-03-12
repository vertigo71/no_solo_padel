import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/firebase.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/register_model.dart';
import '../../models/parameter_model.dart';

final String _classString = 'RegisterPage'.toUpperCase();

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    AppState appState = context.read<AppState>();
    FirebaseHelper firebaseHelper = context.read<Director>().firebaseHelper;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: firebaseHelper.getRegisterStream(
                  appState.getIntParameterValue(ParametersEnum.registerDaysAgoToView)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.connectionState == ConnectionState.active ||
                    snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return const Text('Error');
                  } else if (snapshot.hasData) {
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
                } else {
                  return Text('Estado: ${snapshot.connectionState}');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
