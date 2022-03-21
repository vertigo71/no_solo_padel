import 'package:package_info_plus/package_info_plus.dart';

import '../models/debug.dart';

final String _classString = 'Environment'.toUpperCase();

class Environment {
  static final Environment _singleton = Environment._internal();

  Environment._internal();

  factory Environment() => _singleton;

  bool _isProduction = false;
  bool _initialized = false;
  PackageInfo? _packageInfo;
  String _appName = '';

  Future<void> initialize() async {
    if (!_initialized) {
      _packageInfo = await PackageInfo.fromPlatform();
      assert(_packageInfo != null);
      _appName = _packageInfo!.appName;
      if (_appName.contains('_dev')) {
        _isProduction = false;
        MyLog().log(_classString, 'Development environment initialized', debugType: DebugType.info);
      } else {
        _isProduction = true;
        MyLog().log(_classString, 'Production environment initialized', debugType: DebugType.info);
      }
      _initialized = true;
    }
  }

  PackageInfo get packageInfo {
    assert(_initialized);
    return _packageInfo!;
  }

  bool get isProduction {
    assert(_initialized);
    return _isProduction;
  }

  bool get isDevelopment {
    assert(_initialized);
    return !_isProduction;
  }

  bool get isInitialized => _initialized;
}
