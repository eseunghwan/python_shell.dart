import "dart:io";

import "package:intl/intl.dart";
import "package:path/path.dart" as path;

import "../config.dart" as config;
import "instance.dart";

class ShellManager {
  static ShellInstance createInstance(
      {String? instanceName, List<String>? pythonRequires, bool echo = true}) {
    instanceName = instanceName ??
        DateFormat("yyyy.MM.dd.HH.mm.ss").format(DateTime.now());

    if (echo) print("Creating shell instance [$instanceName]...");
    String instanceDir = path.join(config.instanceDir, instanceName);

    if (Directory(instanceDir).existsSync()) {
      return ShellManager.getInstance(instanceName);
    } else {
      Directory(instanceDir).createSync();
      String tempDir = path.join(instanceDir, "temp");
      Directory(tempDir).createSync();

      if (echo) print("Creating virtualenv...");
      String envDir = path.join(instanceDir, "env");
      String envPython = Platform.isWindows
          ? path.join(envDir, "Scripts", "python.exe")
          : path.join(envDir, "bin", "python");
      var instance = ShellInstance(
          name: instanceName, pythonPath: envPython, tempDir: tempDir);

      ProcessResult createVirtualEnv = Process.runSync(
          config.defaultPythonPath, ["-m", "virtualenv", envDir]);

      if (createVirtualEnv.exitCode != 0) {
        print(
            'Error for createVirtualEnv, exist code ${createVirtualEnv.exitCode}\n'
            'Stdout: ${createVirtualEnv.stdout}\nStderr: ${createVirtualEnv.stderr}');
      }

      if (pythonRequires != null) {
        instance.installRequires(pythonRequires);
      }
      if (echo) print("Virtualenv created.");

      return instance;
    }
  }

  static ShellInstance getInstance(String instanceName) {
    String instanceDir = path.join(config.instanceDir, instanceName);
    if (Directory(instanceDir).existsSync()) {
      return ShellInstance(
          name: instanceName,
          pythonPath: Platform.isWindows
              ? path.join(instanceDir, "env", "Scripts", "python.exe")
              : path.join(instanceDir, "env", "bin", "python"),
          tempDir: path.join(instanceDir, "temp"));
    } else {
      return ShellManager.createInstance(
          instanceName: instanceName, echo: false);
    }
  }

  static void removeInstance(ShellInstance instance) {
    instance.remove();
  }

  static void clear() {
    var instances = Directory(config.instanceDir)
        .listSync()
        .whereType<Directory>()
        .toList();
    instances
        .where((instanceDir) => path.basename(instanceDir.path) != "default")
        .forEach((instanceDir) {
      if (instanceDir.existsSync()) {
        instanceDir.deleteSync(recursive: true);
      }
    });

    var temps = Directory(config.tempDir).listSync();
    temps.whereType<Directory>().forEach((directory) {
      directory.deleteSync(recursive: true);
    });
    temps.whereType<File>().forEach((file) {
      file.deleteSync();
    });
  }
}
