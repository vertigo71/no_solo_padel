
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../database/db_authentication.dart';
import '../../database/db_firebase_helpers.dart';
import '../../interface/if_app_state.dart';
import '../../models/md_debug.dart';
import '../../models/md_exception.dart';
import '../../models/md_user.dart';
import '../../utilities/ui_helpers.dart';

final String _classString = 'ProfilePanel'.toUpperCase();

// fields of the form. avatarUrl field is taken care of individually
enum _FormFieldsEnum {
  name(label: 'Nombre (por este te conocerán los demás)', obscuredText: false, mayBeEmpty: false),
  emergencyInfo(label: 'Información de emergencia', obscuredText: false, mayBeEmpty: true),
  user(label: 'Usuario (para conectarte a la aplicación)', obscuredText: false, mayBeEmpty: false),
  actualPwd(label: 'Contraseña Actual', obscuredText: true, mayBeEmpty: true),
  newPwd(label: 'Nueva Contraseña', obscuredText: true, mayBeEmpty: true),
  checkPwd(label: 'Repetir contraseña', obscuredText: true, mayBeEmpty: true),
  ;

  final String label;
  final bool obscuredText;
  final bool mayBeEmpty;

  const _FormFieldsEnum({
    required this.label,
    required this.obscuredText,
    required this.mayBeEmpty,
  });
}

class ProfilePanel extends StatefulWidget {
  const ProfilePanel({super.key});

  @override
  ProfilePanelState createState() {
    return ProfilePanelState();
  }
}

class ProfilePanelState extends State<ProfilePanel> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  Uint8List? _compressedImageData; // Store the compressed image disk file in memory

  late AppState appState;

  @override
  void initState() {
    super.initState();

    appState = context.read<AppState>();
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    MyLog.log(_classString, 'Building', level: Level.FINE);

    ImageProvider<Object>? imageProvider;
    try {
      if (_compressedImageData != null) {
        // if user has picked an image, use it
        imageProvider = MemoryImage(_compressedImageData!);
      } else if (appState.isLoggedUser && appState.loggedUser!.avatarUrl != null) {
        // else, if there is an image in firebase storage
        imageProvider = NetworkImage(appState.loggedUser!.avatarUrl!);
      }
    } catch (e) {
      MyLog.log(_classString, 'Error building image', level: Level.SEVERE, indent: true);
      UiHelper.showMessage(context, 'Error obteniendo la imagen de perfil');
      imageProvider = null;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._FormFieldsEnum.values.map((field) => _buildFormField(field)),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black87, // Border color
                      width: 0.5, // Border width
                    ),
                    borderRadius: BorderRadius.circular(6.0), // Rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.0,
                      children: [
                        // Show image if picked or uploaded
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blueAccent,
                          backgroundImage: imageProvider,
                          child: imageProvider == null
                              ? Text('?', style: TextStyle(fontSize: 24, color: Colors.white))
                              : null,
                        ),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Seleccionar\nAvatar', textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 26.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _formValidate,
                      child: const Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add the _pickImage function
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _shrinkAvatar(pickedFile, maxHeight: 256, maxWidth: 256).then((Uint8List? compressedBytes) {
        if (compressedBytes != null) {
          setState(() {
            _compressedImageData = compressedBytes;
          });
        } else {
          MyLog.log(_classString, 'Error loading avatar', level: Level.SEVERE, indent: true);
          if (mounted) UiHelper.showMessage(context, 'Error al cargar la imagen');
        }
      }).catchError((e) {
        MyLog.log(_classString, 'Error shrinking avatar: ${e.toString()}', level: Level.SEVERE, indent: true);
        if (mounted) UiHelper.showMessage(context, 'Error al comprimir la imagen\n${e.toString()}');
      });
    }
  }

  Future<Uint8List?> _shrinkAvatar(XFile imageFile, {required int maxWidth, required int maxHeight}) async {
    MyLog.log('_classString', 'Shrinking avatar: ${imageFile.path}');

    Uint8List imageBytes = await imageFile.readAsBytes();

    Uint8List compressedImage = await FlutterImageCompress.compressWithList(
      imageBytes,
      minHeight: 512,
      minWidth: 512,
      quality: 95,
    );

    MyLog.log('_classString', 'Avatar original (kB): ${imageBytes.length / 1000}');
    MyLog.log('_classString', 'Avatar compressed (kB): ${compressedImage.length / 1000}');

    return compressedImage;
  }

  Widget _buildFormField(_FormFieldsEnum formFieldEnum) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilderTextField(
        name: formFieldEnum.name,
        initialValue: _getInitialValue(formFieldEnum),
        decoration: InputDecoration(
          labelText: formFieldEnum.label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
        ),
        obscureText: formFieldEnum.obscuredText,
        validator: FormBuilderValidators.compose([
          if (!formFieldEnum.mayBeEmpty) FormBuilderValidators.required(errorText: 'No puede estar vacío'),
        ]),
      ),
    );
  }

  String _getInitialValue(_FormFieldsEnum formFieldEnum) {
    final MyUser? loggedUser = appState.loggedUser;

    if (loggedUser == null) {
      MyLog.log(_classString, '_getInitialValue loggedUser is null', level: Level.SEVERE);
      throw MyException('No se ha podido obtener el usuario conectado', level: Level.SEVERE );
    }

    switch (formFieldEnum) {
      case _FormFieldsEnum.name:
        return loggedUser.name;
      case _FormFieldsEnum.emergencyInfo:
        return loggedUser.emergencyInfo;
      case _FormFieldsEnum.user:
        return loggedUser.email.split('@')[0];
      default:
        return '';
    }
  }

  Future<void> _formValidate() async {
    MyLog.log(_classString, '_formValidate', level: Level.FINE);
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formValues = _formKey.currentState?.value;

      final newName = formValues?[_FormFieldsEnum.name.name] ?? '';
      final newEmergencyInfo = formValues?[_FormFieldsEnum.emergencyInfo.name] ?? '';
      final newEmail = formValues?[_FormFieldsEnum.user.name]?.toLowerCase() + MyUser.kEmailSuffix ?? '';
      final actualPwd = formValues?[_FormFieldsEnum.actualPwd.name] ?? '';
      final newPwd = formValues?[_FormFieldsEnum.newPwd.name] ?? '';
      final checkPwd = formValues?[_FormFieldsEnum.checkPwd.name] ?? '';

      MyLog.log(_classString, '_formValidate $newName', indent: true);
      MyLog.log(_classString, '_formValidate $newEmergencyInfo', indent: true);
      MyLog.log(_classString, '_formValidate $newEmail', indent: true);
      MyLog.log(_classString, '_formValidate $actualPwd', indent: true);
      MyLog.log(_classString, '_formValidate $newPwd', indent: true);
      MyLog.log(_classString, '_formValidate $checkPwd', indent: true);

      // logged user
      final MyUser? loggedUser = appState.loggedUser;

      if (loggedUser == null) {
        MyLog.log(_classString, '_formValidate loggedUser is null', level: Level.SEVERE);
        throw MyException('No se ha podido obtener el usuario conectado' ,level: Level.SEVERE );
      }

      // Validation and Update Logic
      bool isValid = _checkName(newName, loggedUser);
      if (!isValid) return;

      isValid = _checkEmail(newEmail, actualPwd, loggedUser);
      if (!isValid) return;

      isValid = _checkAllPwd(actualPwd, newPwd, checkPwd);
      if (!isValid) return;

      const String kYesOption = 'SI';
      const String kNoOption = 'NO';
      String response =
          await UiHelper.myReturnValueDialog(context, '¿Seguro que quieres actualizar?', kYesOption, kNoOption);
      if (response.isEmpty || response == kNoOption) return;

      List<String> updatedFields = [];

      // Handle name update
      if (newName != loggedUser.name) {
        isValid = await _updateName(newName, loggedUser);
        if (!isValid) return;
        updatedFields.add('Nombre');
      }

      // Handle emergency info update
      if (newEmergencyInfo != loggedUser.emergencyInfo) {
        isValid = await _updateEmergencyInfo(newEmergencyInfo, updatedFields, loggedUser);
        if (!isValid) return;
        updatedFields.add('Información de emergencia');
      }

      // Handle email update
      if (newEmail != loggedUser.email) {
        isValid = await _updateEmail(newEmail, actualPwd, updatedFields, loggedUser);
        if (!isValid) return;
        updatedFields.add('Correo');
      }

      // Handle password update
      if (newPwd.isNotEmpty) {
        isValid = await _updatePwd(actualPwd, newPwd);
        if (!isValid) return;
        updatedFields.add('Contraseña');
      }

      // Handle avatar upload
      if (_compressedImageData != null) {
        isValid = await _updateAvatar(updatedFields, loggedUser);
        if (!isValid) return;
        updatedFields.add('Avatar');
      }

      if (updatedFields.isNotEmpty) {
        if (mounted) UiHelper.showMessage(context, 'Los campos: ${updatedFields.join(', ')}\nhan sido actualizados');
      } else {
        if (mounted) UiHelper.showMessage(context, 'Ningún dato para actualizar');
      }
    }
  }

  bool _checkName(String newName, MyUser loggedUser) {
    // newName is not somebody else's

    MyLog.log(_classString, 'checkName $newName');

    if (newName != loggedUser.name) {
      MyUser? user = appState.getUserByName(newName);
      if (user != null) {
        UiHelper.showMessage(context, 'Ya hay un usuario con ese nombre');
        return false;
      }
    }

    return true;
  }

  Future<bool> _updateName(String newName, MyUser loggedUser) async {
    MyLog.log(_classString, 'updateName $newName');

    loggedUser.name = newName;

    try {
      await FbHelpers().updateUser(loggedUser);
    } catch (e) {
      MyLog.log(_classString, 'updateName Error al actualizar el nombre del usuario',
          level: Level.SEVERE, indent: true);
      return false;
    }

    return true;
  }

  Future<bool> _updateEmergencyInfo(
      String newEmergencyInfo, final List<String> updatedFields, MyUser loggedUser) async {
    MyLog.log(_classString, 'updateEmergencyInfo $newEmergencyInfo');

    loggedUser.emergencyInfo = newEmergencyInfo;

    try {
      await FbHelpers().updateUser(loggedUser);
    } catch (e) {
      _showErrorMessage('Error al actualizar la información de emergencia del usuario', updatedFields);
      MyLog.log(_classString, 'updateEmergencyInfo Error al actualizar  la información de emergencia del usuario',
          level: Level.SEVERE, indent: true);
      return false;
    }

    return true;
  }

  bool _checkEmail(String newEmail, String actualPwd, MyUser loggedUser) {
    // newEmail is not somebody else's
    MyLog.log(_classString, 'checkEmail $newEmail');

    if (newEmail != loggedUser.email) {
      MyUser? user = appState.getUserByEmail(newEmail);
      if (user != null) {
        UiHelper.showMessage(context, 'Ya hay un usuario con ese correo');
        return false;
      }
      if (actualPwd.isEmpty) {
        UiHelper.showMessage(context, 'Para cambiar el usuario, introduzca tambien la contraseña actual');
        return false;
      }
    }
    return true;
  }

  Future<bool> _updateEmail(
      String newEmail, String actualPwd, final List<String> updatedFields, MyUser loggedUser) async {
    MyLog.log(_classString, 'updateEmail $newEmail');

    String response = await AuthenticationHelper.updateEmail(newEmail: newEmail, actualPwd: actualPwd);

    if (response.isNotEmpty) {
      if (mounted) UiHelper.myAlertDialog(context, response);
      return false;
    }

    loggedUser.email = newEmail;

    try {
      await FbHelpers().updateUser(loggedUser);
    } catch (e) {
      _showErrorMessage('Error al actualizar el correo del usuario en la base de datos', updatedFields);
      MyLog.log(_classString, 'updateEmail Error al actualizar el correo del usuario en la base de datos',
          level: Level.SEVERE, indent: true);
      return false;
    }

    return true;
  }

  bool _checkAllPwd(String actualPwd, String newPwd, String checkPwd) {
    MyLog.log(_classString, 'checkAllPwd');

    if (newPwd != checkPwd) {
      UiHelper.showMessage(context, 'Las dos contraseñas no coinciden');
      return false;
    }
    if (newPwd.isNotEmpty && actualPwd.isEmpty) {
      UiHelper.showMessage(context, 'Para cambiar la contraseña, introduzca tambien la contraseña actual');
      return false;
    }
    return true;
  }

  Future<bool> _updatePwd(String actualPwd, String newPwd) async {
    MyLog.log(_classString, 'updatePwd');

    String response = await AuthenticationHelper.updatePwd(actualPwd: actualPwd, newPwd: newPwd);

    if (response.isNotEmpty) {
      if (mounted) UiHelper.myAlertDialog(context, response);
      return false;
    }
    return true;
  }

  Future<bool> _updateAvatar(final List<String> updatedFields, MyUser loggedUser) async {
    MyLog.log(_classString, 'Uploading new avatar', indent: true);
    try {
      await FbHelpers().updateUser(loggedUser, _compressedImageData);
      return true; // Return true on success
    } catch (e) {
      MyLog.log(_classString, 'Error al subir el avatar: ${e.toString()}', level: Level.SEVERE);
      _showErrorMessage('Error al subir el avatar\n${e.toString()}', updatedFields);
      return false;
    }
  }

  void _showErrorMessage(String message, final List<String> updatedFields) {
    if (updatedFields.isNotEmpty) message += '\n\n(se ha actualizado los campos: ${updatedFields.join(', ')})';
    UiHelper.showMessage(context, message);
  }
}
