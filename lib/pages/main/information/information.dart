import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:no_solo_padel/utilities/ut_list_view.dart';

import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../interface/if_app_state.dart';
import '../../../interface/if_director.dart';
import '../../../models/md_debug.dart';
import '../../../models/md_user.dart';
import '../../../routes/routes.dart';
import '../../../utilities/ui_helpers.dart';
import 'modal_modify_user.dart';

final String _classString = 'InformationPanel'.toUpperCase();
const int kNumberOfTrophies = 5;

class InformationPanel extends StatefulWidget {
  const InformationPanel({super.key});

  @override
  State<InformationPanel> createState() => _InformationPanelState();
}

class _InformationPanelState extends State<InformationPanel> {
  bool _sortedByName = false;
  late Future<Map<MyUser, List<bool>>> userListOfTrophies;

  @override
  void initState() {
    super.initState();
    userListOfTrophies = context.read<Director>().playersLastTrophies();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Consumer<AppState>(builder: (context, appState, child) {
      final MyListView users = _sortedByName ? appState.usersSortedByName : appState.usersSortedByRanking;

      return Scaffold(
        appBar: _buildAppBar(appState),
        body: FutureBuilder<Map<MyUser, List<bool>>>(
          future: userListOfTrophies,
          builder: (context, snapshot) {
            final Map<MyUser, List<bool>>? userTrophiesData = snapshot.data;

            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];
                final displayIndex = index + 1; // Add 1 for 1-based indexing
                final List<bool>? lastGamesWins = userTrophiesData?[user]?.take(kNumberOfTrophies).toList();

                return UiHelper.buildUserInfoTile(
                  context,
                  user,
                  index: displayIndex,
                  lastGamesWins: lastGamesWins,
                  // logged user can only edit users with higher or equal rank
                  onPressed: () => context.pushNamed(AppRoutes.kInfoUser, extra: ['$displayIndex', user.id]),
                );
              },
            );
          },
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
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
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
