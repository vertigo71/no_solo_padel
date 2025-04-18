import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

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
  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Consumer<AppState>(builder: (context, appState, child) {
      return Scaffold(
        appBar: _buildAppBar(appState),
        body: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: appState.unmodifiableUsers.indexed.map((indexedUser) {
              final index = indexedUser.$1 + 1; // Add 1 for 1-based indexing
              final user = indexedUser.$2;
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surfaceBright,
                      child: Text('$index', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: UiHelper.userInfoTile(
                      user,
                      // logged user can only edit users with higher or equal rank
                      appState.loggedUser != null &&
                              appState.isLoggedUserAdminOrSuper &&
                              appState.loggedUser!.userType.index >= user.userType.index
                          ? () => _modifyUserModal(context, user)
                          : null,
                    ),
                  ),
                ],
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
          child: Row(
            spacing: 10,
            // mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(width: 10),
              Flexible(flex: 2, child: const Text('Ranking')),
              Flexible(
                flex: 1,
                child: FormBuilderSwitch(
                  name: 'switch',
                  title: const Text(''),
                  initialValue: appState.isUsersSortedByName,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      appState.sortUsers(sortBy: value ? UsersSortBy.name : UsersSortBy.ranking, notify: true);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Flexible(flex: 2, child: const Text('Nombre')),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }

  Future _modifyUserModal(BuildContext context, MyUser user) {
    return UiHelper.modalPanel(context, user.name, ModifyUserModal(user: user));
  }
}
