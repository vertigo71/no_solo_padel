import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/firebase.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';

final String _classString = 'UserDeletePanel'.toUpperCase();

class UserDeletePanel extends StatefulWidget {
  const UserDeletePanel({Key? key}) : super(key: key);

  @override
  _UserDeletePanelState createState() => _UserDeletePanelState();
}

class _UserDeletePanelState extends State<UserDeletePanel> {
  String dropdownValue = '';

  late AppState appState;
  late FirebaseHelper firebaseHelper;

  @override
  void initState() {
    MyLog().log(_classString, 'initState');
    appState = context.read<AppState>();
    firebaseHelper = context.read<Director>().firebaseHelper;
    super.initState();
  }

  @override
  void dispose() {
    MyLog().log(_classString, 'dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    return Container(
      height: 100,
      padding: const EdgeInsets.all(18.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          // padding: const EdgeInsets.all(15),
          borderRadius: BorderRadius.circular(5),
          // border: const BorderSide(color: Colors.black12, width: 1),
          // dropdownButtonColor: Colors.white,
          // value: dropdownValue,
          onChanged: (newValue) {
            setState(() {
              dropdownValue = newValue.toString();
            });
          },
          items: ['FC Barcelona', 'Real Madrid', 'Villareal', 'Manchester City']
              .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
