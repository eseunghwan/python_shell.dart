import "dart:io";

import "package:path/path.dart" as path;

String appDir = path.join(
    Platform.environment[Platform.isWindows ? "USERPROFILE" : "HOME"]!,
    ".python_shell.dart");
String tempDir = path.join(appDir, "temp");
String instanceDir = path.join(appDir, "instances");

String defaultPythonVersion = "3.10.6";
String defaultPythonPath = "python3";

String checkPythonVersion(String rawPythonVersion) {
  String realPythonVersion = "3.10.6";

  var versions = rawPythonVersion.split(".");
  if (versions.length == 3) {
    if (rawPythonVersion.endsWith(".")) {
      if (versions.last != "") {
        versions.removeLast();
        realPythonVersion = versions.join(".");
      }
    } else {
      realPythonVersion = rawPythonVersion;
    }
  } else if (versions.length == 2) {
    if (rawPythonVersion.endsWith(".")) {
      if (versions.last != "") {
        realPythonVersion = "${versions.join(".")}.0";
      }
    } else {
      realPythonVersion = "$rawPythonVersion.0";
    }
  }

  return realPythonVersion;
}
