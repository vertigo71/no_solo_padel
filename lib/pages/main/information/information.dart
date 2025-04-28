import 'dart:collection';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../interface/if_app_state.dart';
import '../../../models/md_debug.dart';
import '../../../models/md_user.dart';
import '../../../utilities/ui_helpers.dart';
import 'modal_modify_user.dart';

final String _classString = 'InformationPanel'.toUpperCase();

class InformationPanel extends StatefulWidget {
  const InformationPanel({super.key});

  @override
  State<InformationPanel> createState() => _InformationPanelState();
}

class _InformationPanelState extends State<InformationPanel> {
  bool _sortedByName = false;

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Consumer<AppState>(builder: (context, appState, child) {
      Iterable<MyUser> users = _sortedByName ? appState.usersSortedByName : appState.usersSortedByRanking;
      return Scaffold(
        appBar: _buildAppBar(appState),
        body: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: users.indexed.map((indexedUser) {
              final index = indexedUser.$1 + 1; // Add 1 for 1-based indexing
              final user = indexedUser.$2;

              return UiHelper.buildUserInfoTile(
                context,
                user,
                index: index,
                onPressed:
                    // logged user can only edit users with higher or equal rank
                    appState.loggedUser != null &&
                            appState.isLoggedUserAdminOrSuper &&
                            appState.loggedUser!.userType.index >= user.userType.index
                        ? () => _modifyUserModal(context, user)
                        : null,
              );
            }),
          ).toList(), // Convert the Iterable<Widget> to List<Widget>
        ),
      );
    });
  }

  PreferredSizeWidget? _buildAppBar(AppState appState) {
    MyLog.log(_classString, 'Building AppBar', level: Level.FINE);
    return AppBar(
      actions: [
        // typical layout: expanded, row, expanded, ...
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16,8,0,8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 8,
              children: [
                const Text('Ranking'),
                UiHelper.myToggleButton(
                  context: context,
                  value: _sortedByName,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortedByName = value;
                      });
                    }
                  },
                ),
                const Text('Nombre'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future _modifyUserModal(BuildContext context, MyUser user) {
    return UiHelper.modalPanel(context, user.name, ModifyUserModal(user: user));
  }
}
