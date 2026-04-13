import 'package:planify/struct/appState.dart';
import 'package:package_info_plus/package_info_plus.dart';

Map<String, dynamic> appStateSettings = {};
bool isDatabaseCorrupted = false;
String databaseCorruptedError = "";
bool isDatabaseImportedOnThisSession = false;
PackageInfo? packageInfoGlobal;


