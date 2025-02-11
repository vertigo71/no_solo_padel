import 'package:logging/logging.dart';
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
      _initialized = true;
      assert(_packageInfo != null);
      _appName = _packageInfo!.appName;
      if (_appName.contains('_dev')) {
        _isProduction = false;
        MyLog.log(_classString, 'Development environment initialized', level: Level.INFO);
      } else {
        _isProduction = true;
        MyLog.log(_classString, 'Production environment initialized', level: Level.INFO);
      }
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
