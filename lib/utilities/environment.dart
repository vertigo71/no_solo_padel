import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/debug.dart';

final String _classString = 'Environment'.toUpperCase();
// these variables must identical to the ones defined in deploy.sh
const String devEnvironment = 'dev';
const String stageEnvironment = 'stage';
const String prodEnvironment = 'prod';

class Environment {
  static final Environment _singleton = Environment._internal();

  Environment._internal();

  factory Environment() => _singleton;

  String _flavor = '';
  bool _initialized = false;
  PackageInfo? _packageInfo;

  Future<void> initialize({required String flavor}) async {
    if (!_initialized) {
      _packageInfo = await PackageInfo.fromPlatform();
      _initialized = true;
      assert(_packageInfo != null);
      _flavor = flavor;
      if (flavor == prodEnvironment) {
        MyLog.log(_classString, 'Production environment initialized', level: Level.INFO);
      } else if (flavor == stageEnvironment) {
        MyLog.log(_classString, 'Staging environment initialized', level: Level.INFO);
      } else if (flavor == devEnvironment) {
        MyLog.log(_classString, 'Development environment initialized', level: Level.INFO);
      } else {
        MyLog.log(_classString, 'CRUCIAL ERROR: Unknown environment initialized', level: Level.SEVERE);
      }
    }
  }

  PackageInfo get packageInfo {
    assert(_initialized);
    return _packageInfo!;
  }

  bool get isProduction {
    assert(_initialized);
    return _flavor == prodEnvironment;
  }

  bool get isDevelopment {
    assert(_initialized);
    return _flavor == devEnvironment;
  }

  bool get isStaging {
    assert(_initialized);
    return _flavor == stageEnvironment;
  }

  bool get isInitialized => _initialized;
}
