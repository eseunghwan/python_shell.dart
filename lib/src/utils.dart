
import "dart:io";
import "package:path/path.dart" as path;
import "package:dio/dio.dart";
import "package:archive/archive_io.dart";
import "package:intl/intl.dart";

import "shell.dart";


Future<void> initializeApp(PythonShellConfig config, bool createDefaultEnv) async {
    config.defaultPythonVersion = checkPythonVersion(config.defaultPythonVersion);

    String? userHomeDir = Platform.environment[Platform.isWindows ? "USERPROFILE" : "HOME"];
    String appDir = path.join(userHomeDir!, ".python_shell");
    if (!Directory(appDir).existsSync()) {
        Directory(appDir).createSync(recursive: true);
    }

    String tempDir = path.join(appDir, "temp");
    if (!Directory(tempDir).existsSync()) {
        Directory(tempDir).createSync();
    }

    String instanceDir = path.join(appDir, "instances");
    if (!Directory(instanceDir).existsSync()) {
        Directory(instanceDir).createSync();
    }

    String pythonDir = "";
    if (Platform.isWindows) {
        pythonDir = path.join(appDir, "python");
        if (!Directory(pythonDir).existsSync()) {
            String pythonBinaryFile = path.join(tempDir, "python.zip");
            await Dio().download("https://www.python.org/ftp/python/${config.defaultPythonVersion}/python-${config.defaultPythonVersion}-embed-amd64.zip", pythonBinaryFile);
            await extractFileToDisk(pythonBinaryFile, pythonDir);
            File(pythonBinaryFile).deleteSync();
            config.defaultPythonPath = path.join(pythonDir, "python.exe");
        }
    }

    String pipInstallFile = path.join(tempDir, "get-pip.py");
    await Dio().download("https://bootstrap.pypa.io/pip/get-pip.py", pipInstallFile);
    Process.runSync(config.defaultPythonPath, [ pipInstallFile ], runInShell: true);
    Process.runSync(config.defaultPythonPath, [ "-m", "pip", "install", "virtualenv" ], runInShell: true);
    File(pipInstallFile).deleteSync();

    String defaultEnvDir = path.join(appDir, "defaultEnv");
    if (!Directory(defaultEnvDir).existsSync()) {
        if (createDefaultEnv) {
            Process.runSync(config.defaultPythonPath, [ "-m", "virtualenv", path.join(defaultEnvDir) ]);
            config.defaultPythonEnvPath = Platform.isWindows ? path.join(defaultEnvDir, "Scripts", "python.exe") : path.join(defaultEnvDir, "bin", "python");
        }
    }
    else {
        config.defaultPythonEnvPath = Platform.isWindows ? path.join(defaultEnvDir, "Scripts", "python.exe") : path.join(defaultEnvDir, "bin", "python");
    }

    if (config.defaultPythonEnvPath != null) {
        if (config.pythonRequireFile != null) {
            Process.runSync(config.defaultPythonEnvPath!, [ "-m", "pip", "install", "-r", config.pythonRequireFile! ]);
        }
        else if (config.pythonRequires != null) {
            String tempRequireFile = path.join(tempDir, "defaultRequirements.txt");
            File(tempRequireFile).writeAsStringSync(config.pythonRequires!.join("\n"));
            Process.runSync(config.defaultPythonEnvPath!, [ "-m", "pip", "install", "-r", tempRequireFile ]);
            File(tempRequireFile).deleteSync();
        }
    }

    config.appDir = appDir;
    config.tempDir = tempDir;
    config.instanceDir = instanceDir;
}

String checkPythonVersion(String rawPythonVersion) {
    String realPythonVersion = "3.9.13";

    var versions = rawPythonVersion.split(".");
    if (versions.length == 3) {
        if (rawPythonVersion.endsWith(".")) {
            if (versions.last != "") {
                versions.removeLast();
                realPythonVersion = versions.join(".");
            }
        }
        else {
            realPythonVersion = rawPythonVersion;
        }
    }
    else if (versions.length == 2) {
        if (rawPythonVersion.endsWith(".")) {
            if (versions.last != "") {
                realPythonVersion = "${versions.join(".")}.0";
            }
        }
        else {
            realPythonVersion = "$rawPythonVersion.0";
        }
    }

    return realPythonVersion;
}

Map<String, String> createShellInstance(PythonShellConfig config) {
    String instanceDir = path.join(config.instanceDir!, DateFormat("yyyy.MM.dd.HH.mm.ss").format(DateTime.now()));
    Directory(instanceDir).createSync();

    String instanceEnvDir = path.join(instanceDir, "env");
    Process.runSync(config.defaultPythonPath, [ "-m", "virtualenv", instanceEnvDir ]);

    return {
        "dir": instanceDir,
        "python": Platform.isWindows ? path.join(instanceEnvDir, "Scripts", "python.exe") : path.join(instanceDir, "bin", "python")
    };
}

void removeShellInstance(String instanceDir) {
    if (Directory(instanceDir).existsSync()) {
        Directory(instanceDir).deleteSync(recursive: true);
    }
}
