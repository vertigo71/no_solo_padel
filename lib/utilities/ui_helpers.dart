import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:getwidget/getwidget.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:web/web.dart' as web; // Import the web package

import '../models/md_debug.dart';
import '../models/md_match.dart';
import '../models/md_user.dart';
import 'ut_theme.dart';

final String _classString = 'UiHelper'.toUpperCase();

/// User Interface Helper Functions
abstract class UiHelper {
  /// Builds a `BottomNavigationBarItem` for a `BottomNavigationBar`.
  ///
  /// It takes the `index` of the item, an `icon` widget, a `label` string, and the `selectedIndex`
  /// of the currently active item.
  /// The icon is wrapped in a `Container` with padding and a rounded `BorderRadius`.
  /// The background color of the icon's container changes to `kPrimaryMedium` if the item is selected.
  static BottomNavigationBarItem buildNavItem(
      BuildContext context, int index, Widget icon, String label, int selectedIndex) {
    MyLog.log(_classString, 'BottomNavigationBarItem', level: Level.FINE);

    final isSelected = selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.surfaceDim : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: icon,
      ),
      label: label,
    );
  }

  /// Builds a `ListTile` to display information about a `MyUser`.
  ///
  /// It shows the user's avatar (or a placeholder if the URL is null or invalid),
  /// their name, emergency SOS information (if available), email (username part),
  /// ranking position, user type's display name, login count, and last login date.
  /// If an optional
  ///   `onPressed` callback is provided, the tile becomes tappable.
  ///   `lastGamesWins` is a list of booleans indicating whether the user has won or lost last games.
  ///   `index` is the position of the user in a sorted list. Null for not displaying index
  static Widget buildUserInfoTile(
    BuildContext context,
    MyUser user, {
    List<bool>? lastGamesWins,
    int? index,
    Function? onPressed,
  }) {
    final String sosInfo = user.emergencyInfo.isNotEmpty ? '\nSOS: ${user.emergencyInfo}' : '';

    ImageProvider<Object>? imageProvider;
    try {
      if (user.avatarUrl != null) {
        imageProvider = NetworkImage(user.avatarUrl!);
      }
    } catch (e) {
      MyLog.log(_classString, 'Error building image for user $user', level: Level.WARNING, indent: true);
      imageProvider = null;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          children: [
            if (index != null)
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surfaceBright,
                child: Text('$index', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blueAccent,
              backgroundImage: imageProvider,
              child: imageProvider == null ? Text('?', style: TextStyle(fontSize: 24, color: Colors.white)) : null,
            ),
          ],
        ),
        title: Text('${user.name}$sosInfo'),
        subtitle: lastGamesWins == null
            ? null
            : Row(
                spacing: 3,
                children: lastGamesWins.map((win) {
                  if (win) {
                    return Container(
                      decoration: BoxDecoration(
                        color: kLightGreen,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(Icons.emoji_events_outlined, size: 20),
                    );
                  } else {
                    return Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: kLightRed,
                    );
                  }
                }).toList(),
              ),
        trailing: Text('${user.rankingPos}',
            style: user.isActive
                ? TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                : TextStyle(fontSize: 18, color: kLightRed)),
        onTap: () {
          if (onPressed != null) onPressed();
        },
      ),
    );
  }

  /// Displays a simple modal alert dialog with a title ("¡Atención!") and the provided `text` as content.
  ///
  /// The dialog is not dismissible by tapping outside. It presents a single "Cerrar" (Close) button.
  /// An optional `onDialogClosed` callback function can be provided, which will be executed
  /// after the dialog is closed by pressing the button.
  static void myAlertDialog(BuildContext context, String text, {Function? onDialogClosed}) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('¡Atención!'),
          content: Text(text),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cerrar'),
              onPressed: () {
                context.pop();
                if (onDialogClosed != null) {
                  onDialogClosed(); // Call the optional callback function
                }
              },
            ),
          ],
        ),
      );
    }
  }

  /// Displays a modal dialog with a title ("¡Atención!") and the provided `text` as content.
  ///
  /// It presents up to four `ElevatedButton` options based on the provided `option1`, `option2`,
  /// and optional `option3` and `option4` strings.
  /// The dialog is not dismissible by tapping outside.
  ///
  /// Returns a `Future<String>` that resolves to the text of the button pressed by the user.
  /// If the dialog is dismissed without a button press or if the context is no longer mounted,
  /// it returns an empty string.
  static Future<String> myReturnValueDialog(BuildContext context, String text, String option1, String option2,
      {String option3 = '', String option4 = ''}) async {
    if (context.mounted) {
      dynamic response = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: const Text('¡Atención!'),
                content: Text(text),
                actionsPadding: const EdgeInsets.all(10.0),
                actions: <Widget>[
                  ElevatedButton(
                      child: Text(option1),
                      onPressed: () {
                        Navigator.pop(context, option1);
                      }),
                  ElevatedButton(
                      child: Text(option2),
                      onPressed: () {
                        Navigator.pop(context, option2);
                      }),
                  if (option3.isNotEmpty)
                    ElevatedButton(
                        child: Text(option3),
                        onPressed: () {
                          Navigator.pop(context, option3);
                        }),
                  if (option4.isNotEmpty)
                    ElevatedButton(
                        child: Text(option4),
                        onPressed: () {
                          Navigator.pop(context, option4);
                        }),
                ],
              ));
      if (response is String) {
        return response;
      } else {
        return '';
      }
    }
    return '';
  }

  /// Displays a simple `SnackBar` at the bottom of the screen with the provided `text`.
  ///
  /// This is a convenient way to show short, non-blocking messages to the user,
  /// such as confirmations or brief notifications. The text is displayed with a font size of 16.
  static void showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, style: const TextStyle(fontSize: 16))));
  }

  /// Displays a confirmation modal dialog requiring the user to type a specific text to confirm an action.
  ///
  /// The dialog shows the provided `dialogText` as the main message and instructs the user to type
  /// the `confirmationText` in a `FormBuilderTextField` to proceed.
  /// An optional `errorMessage` can be provided to customize the error message displayed
  /// if the user's input does not match the `confirmationText`.
  ///
  /// Returns `true` if the user types the correct confirmation text and presses 'Confirmar',
  /// and `false` otherwise (if they press 'Cancelar' or fail to type the correct text).
  static Future<bool> showConfirmationModal(
      BuildContext context, String dialogText, String bodyText, String confirmationText,
      {String errorMessage = 'Por favor, escriba "%s" para confirmar.'}) async {
    final confirmationFormKey = GlobalKey<FormBuilderState>();

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surfaceDim,
              title: Text(dialogText),
              content: FormBuilder(
                key: confirmationFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(bodyText, style: TextStyle(fontSize: 14)),
                    SizedBox(height: 30),
                    Text('Escriba "$confirmationText" para confirmar'),
                    FormBuilderTextField(
                      name: 'userConfirmation',
                      validator: FormBuilderValidators.required(errorText: 'No puede estar vacío'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // Cancel
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (confirmationFormKey.currentState!.saveAndValidate()) {
                      final userConfirmation = confirmationFormKey.currentState!.value['userConfirmation'];
                      if (userConfirmation == confirmationText) {
                        Navigator.of(context).pop(true); // Confirm
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMessage.replaceAll('%s', confirmationText))),
                        );
                      }
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Displays a customizable modal dialog using Flutter's `showDialog` and `AlertDialog`.
  ///
  /// The dialog's background color is taken from the theme's `surfaceDim`.
  /// The provided `title` is displayed at the top with a bold, slightly smaller font.
  /// The `child` widget is shown as the main content, constrained to 80% of the screen width
  /// and made vertically scrollable if its height exceeds the available space.
  /// The dialog also includes horizontal padding.
  static Future<void> modalPanel(BuildContext context, String title, Widget child) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceDim,
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 8.0), // Add some horizontal padding
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              // Make content scrollable if it's still too tall
              child: child,
            ),
          ),
        );
      },
    );
  }

  static Widget myCheckBox(
      {required BuildContext context, required void Function(bool?) onChanged, required bool value}) {
    return GFCheckbox(
      onChanged: onChanged,
      value: value,
      size: GFSize.SMALL,
      type: GFCheckboxType.circle,
      activeBgColor: Theme.of(context).primaryColor,
      inactiveBgColor: Theme.of(context).colorScheme.surface,
    );
  }

  static Widget myToggleButton({
    required BuildContext context,
    required void Function(bool?) onChanged,
    required bool value,
  }) {
    return GFToggle(
      onChanged: onChanged,
      value: value,
      enabledTrackColor: kAltDark,
      disabledTrackColor: kAltLight,
      enabledThumbColor: Theme.of(context).colorScheme.surfaceDim,
      disabledThumbColor: Theme.of(context).colorScheme.surfaceDim,
    );
  }

  static Color _getMatchColor(MyMatch match) {
    switch (match.isOpen) {
      case true:
        return Colors.indigo.shade400;
      default:
        return Colors.red;
    }
  }

  static Color getMatchTileColor(MyMatch match) => lighten(_getMatchColor(match), 0.2);

  static Color getMatchAvatarColor(MyMatch match) => lighten(_getMatchColor(match), 0.1);

  static Color getTilePlayingColor(BuildContext context, PlayingState playingState) {
    switch (playingState) {
      case PlayingState.unsigned:
        return Theme.of(context).colorScheme.surface;
      case PlayingState.playing:
      case PlayingState.signedNotPlaying:
      case PlayingState.reserve:
        return kPrimaryMedium;
    }
  }

  static Color darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }

  static Widget buildErrorMessage(
      {required String errorMessage, required String buttonText, Future<void> Function()? onPressed}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Oooopps! Se ha detectado un error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 40),
            onPressed == null
                ? Text(buttonText)
                : ElevatedButton(
                    onPressed: onPressed, // Pass the async function directly
                    child: Text(buttonText),
                  ),
          ],
        ),
      ),
    );
  }

  static void reloadPage() {
    web.window.location.reload();
  }
}

/// TextFormField uppercase formatter: allow = false => deny list
class UpperCaseTextFormatter extends CaseTextFormatter {
  UpperCaseTextFormatter(super.filterPattern, {required super.allow, super.replacementString})
      : super(toUppercase: true);
}

/// TextFormField lowercase formatter: allow = false => deny list
class LowerCaseTextFormatter extends CaseTextFormatter {
  LowerCaseTextFormatter(super.filterPattern, {required super.allow, super.replacementString})
      : super(toUppercase: false);
}

/// TextFormField uppercase/lowercase formatter: allow = false => deny list
class CaseTextFormatter extends FilteringTextInputFormatter {
  CaseTextFormatter(super.filterPattern, {required this.toUppercase, required super.allow, super.replacementString});

  final bool toUppercase;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    TextEditingValue value = super.formatEditUpdate(oldValue, newValue);
    return TextEditingValue(
      text: toUppercase ? value.text.toUpperCase() : value.text.toLowerCase(),
      selection: value.selection,
    );
  }
}
