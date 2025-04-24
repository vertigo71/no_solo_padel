import 'package:simple_logger/simple_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/md_debug.dart';

final String _classString = 'Environment'.toUpperCase();
// these variables must identical to the ones defined in deploy.sh
const String kDevEnvironment = 'dev';
const String kStageEnvironment = 'stage';
const String kProdEnvironment = 'prod';

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
      if (flavor == kProdEnvironment) {
        MyLog.log(_classString, 'Production environment initialized');
      } else if (flavor == kStageEnvironment) {
        MyLog.log(_classString, 'Staging environment initialized');
      } else if (flavor == kDevEnvironment) {
        MyLog.log(_classString, 'Development environment initialized');
      } else {
        MyLog.log(_classString, 'CRUCIAL ERROR: Unknown environment initialized', level: Level.SEVERE);
      }
    }
  }

  String get flavor => _flavor;

  PackageInfo get packageInfo {
    assert(_initialized);
    return _packageInfo!;
  }

  bool get isProduction {
    assert(_initialized);
    return _flavor == kProdEnvironment;
  }

  bool get isDevelopment {
    assert(_initialized);
    return _flavor == kDevEnvironment;
  }

  bool get isStaging {
    assert(_initialized);
    return _flavor == kStageEnvironment;
  }

  bool get isInitialized => _initialized;

  String get version => packageInfo.version;

  String get buildNumber => packageInfo.buildNumber;

  String get fullVersion => '${packageInfo.version}+${packageInfo.buildNumber}';

  String get appName => packageInfo.appName;

  String get packageName => packageInfo.packageName;
}
