
import "dart:io";

import "package:archive/archive_io.dart";
import "package:dio/dio.dart";
import "package:intl/intl.dart";
import "package:path/path.dart" as path;

import "shell.dart";


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

String getPythonPthFile(PythonShellConfig config, String pythonDir) {
    return path.join(pythonDir, "python${config.defaultPythonVersion.replaceAll(".${config.defaultPythonVersion.split(".").last}", "").replaceAll(".", "")}._pth");
}

void clearShellInstance(PythonShellConfig config, String instanceName) {
    List<FileSystemEntity> tempFiles;
    if (instanceName.toLowerCase() == "default") {
        tempFiles = Directory(path.join(config.instanceDir!, "default", "temp")).listSync();
    }
    else {
        tempFiles = Directory(path.join(config.instanceDir!, instanceName, "temp")).listSync();
    }

    tempFiles.whereType<Directory>().forEach((directory) {
        directory.deleteSync(recursive: true);
    });
    tempFiles.whereType<File>().forEach((file) {
        file.deleteSync();
    });
}

Map<String, String> createShellInstance(PythonShellConfig config, { String? instanceName, bool echo = true }) {
    instanceName = instanceName ?? DateFormat("yyyy.MM.dd.HH.mm.ss").format(DateTime.now());
    if (echo) print("Creating shell instance [$instanceName]...");
    String instanceDir = path.join(config.instanceDir!, instanceName), envPython;

    if (!Directory(instanceDir).existsSync()) {
        Directory(instanceDir).createSync();
        Directory(path.join(instanceDir, "temp")).createSync();
        envPython = createVirtualEnv(config, instanceName, echo: echo);
    }
    else {
        clearShellInstance(config, instanceName);
        envPython = getVirtualEnv(config, instanceName);
    }
    if (echo) print("Shell instance created.");

    return {
        "dir": instanceDir,
        "python": envPython
    };
}

String createVirtualEnv(PythonShellConfig config, String instanceName, { List<String>? pythonRequires, bool echo = true }) {
    if (echo) print("Creating virtualenv...");
    pythonRequires = pythonRequires ?? config.pythonRequires;

    String envDir;
    if (instanceName.toLowerCase() == "default") {
        envDir = path.join(config.instanceDir!, "default", "env");
        config.defaultPythonEnvPath = Platform.isWindows ? path.join(envDir, "Scripts", "python.exe") : path.join(envDir, "bin", "python");
    }
    else {
        envDir = path.join(config.instanceDir!, instanceName, "env");
    }

    Process.runSync(config.defaultPythonPath, [ "-m", "virtualenv", envDir ]);
    String envPython = Platform.isWindows ? path.join(envDir, "Scripts", "python.exe") : path.join(envDir, "bin", "python");
    installRequiresToEnv(config, envPython, pythonRequires: pythonRequires, echo: echo);
    if (echo) print("Virtualenv created.");

    return envPython;
}

void deleteShellInstance(PythonShellConfig config, String instanceName) {
    if (instanceName.toLowerCase() == "default") {
        Directory(path.join(config.instanceDir!, "default")).deleteSync(recursive: true);
    }
    else {
        Directory(path.join(config.instanceDir!, instanceName)).deleteSync(recursive: true);
    }
}

Map<String, String> getShellInstance(PythonShellConfig config, String instanceName) {
    String instanceDir = path.join(config.instanceDir!, instanceName);
    if (Directory(instanceDir).existsSync()) {
        return {
            "dir": path.join(config.instanceDir!, instanceName), "python": getVirtualEnv(config, instanceName)
        };
    }
    else {
        return createShellInstance(config, instanceName: instanceName, echo: false);
    }
}

String getVirtualEnv(PythonShellConfig config, String instanceName) {
    String envDir;
    if (instanceName.toLowerCase() == "default") {
        envDir = path.join(config.instanceDir!, "default", "env");
        config.defaultPythonEnvPath = Platform.isWindows ? path.join(envDir, "Scripts", "python.exe") : path.join(envDir, "bin", "python");
    }
    else {
        envDir = path.join(config.instanceDir!, instanceName, "env");
    }

    return Platform.isWindows ? path.join(envDir, "Scripts", "python.exe") : path.join(envDir, "bin", "python");
}

Future<void> initializeApp(PythonShellConfig config, bool createDefaultEnv) async {
    print("Initializing shell...");
    config.defaultPythonVersion = checkPythonVersion(config.defaultPythonVersion);

    print("Check shell app directory...");
    String? userHomeDir = Platform.environment[Platform.isWindows ? "USERPROFILE" : "HOME"];
    String appDir = path.join(userHomeDir!, ".python_shell.dart");
    if (!Directory(appDir).existsSync()) {
        Directory(appDir).createSync(recursive: true);
    }
    config.appDir = appDir;

    String tempDir = path.join(appDir, "temp");
    if (!Directory(tempDir).existsSync()) {
        Directory(tempDir).createSync();
    }
    config.tempDir = tempDir;

    String instanceDir = path.join(appDir, "instances");
    if (!Directory(instanceDir).existsSync()) {
        Directory(instanceDir).createSync();
    }
    config.instanceDir = instanceDir;
    print("Shell app directory check finished.");

    String pythonDir = "";
    if (Platform.isWindows) {
        print("Check default python binary files...");
        pythonDir = path.join(appDir, "python");
        if (!Directory(pythonDir).existsSync()) {
            String pythonBinaryFile = path.join(tempDir, "python.zip");
            await Dio().download("https://www.python.org/ftp/python/${config.defaultPythonVersion}/python-${config.defaultPythonVersion}-embed-amd64.zip", pythonBinaryFile);
            await extractFileToDisk(pythonBinaryFile, pythonDir);
            File(pythonBinaryFile).deleteSync();

            File(getPythonPthFile(config, pythonDir)).writeAsStringSync(File(getPythonPthFile(config, pythonDir)).readAsStringSync().replaceAll("#import site", "import site"));
        }
        print("Python check finished.");

        config.defaultPythonPath = path.join(pythonDir, "python.exe");
    }

    if (File(config.defaultPythonPath).existsSync()) {
        print("Default settings for virtualenv...");
        var result = Process.runSync(config.defaultPythonPath, [ "-m", "pip", "install", "pip", "--upgrade" ]);
        if (result.stderr.toString().trim() != "") {
            String pipInstallFile = path.join(tempDir, "get-pip.py");
            await Dio().download("https://bootstrap.pypa.io/pip/get-pip.py", pipInstallFile);
            Process.runSync(config.defaultPythonPath, [ pipInstallFile ]);
            File(pipInstallFile).deleteSync();
        }

        Process.runSync(config.defaultPythonPath, [ "-m", "pip", "install", "virtualenv", "--upgrade" ]);
        print("Virtualenv settings finished.");
    }

    String defaultEnvDir = path.join(appDir, "defaultEnv");
    if (createDefaultEnv) {
        print("Creating default env...");
        if (!Directory(defaultEnvDir).existsSync()) {
            var instanceMaps = createShellInstance(config, instanceName: "default", echo: true);
            config.defaultPythonEnvPath = instanceMaps["python"]!;
        }
        else {
            config.defaultPythonEnvPath = getVirtualEnv(config, "default");
        }
        print("Default env created.");
    }
    // else {
    //     installRequiresToEnv(config, config.defaultPythonPath);
    // }

    print("Shell initialized.");
}

void installRequiresToEnv(PythonShellConfig config, String envPython, { List<String>? pythonRequires, bool echo = true }) {
    pythonRequires = pythonRequires ?? config.pythonRequires;

    if (echo) print("Installing requirements...");
    if (config.pythonRequireFile != null) {
        Process.runSync(envPython, [ "-m", "pip", "install", "-r", config.pythonRequireFile! ]);
    }
    else if (pythonRequires != null) {
        String tempPythonRequireFile = path.join(config.tempDir!, "${DateFormat("yyyy.MM.dd.HH.mm.ss").format(DateTime.now())}.txt");
        File(tempPythonRequireFile).writeAsStringSync(pythonRequires.join("\n"));
        Process.runSync(envPython, [ "-m", "pip", "install", "-r", tempPythonRequireFile ]);
        File(tempPythonRequireFile).deleteSync();
    }
    if (echo) print("Requirements installed.");
}

void removeShellInstance(String instanceDir) {
    if (Directory(instanceDir).existsSync()) {
        Directory(instanceDir).deleteSync(recursive: true);
    }
}
