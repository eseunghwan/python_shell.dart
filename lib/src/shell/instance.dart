import "dart:io";

import "package:intl/intl.dart";
import "package:path/path.dart" as path;

import "../config.dart" as config;
import "../listener.dart";

class ShellInstance {
  String name;
  String pythonPath;
  String tempDir;
  String? defaultWorkingDirectory;

  ShellInstance({
    required this.name,
    required this.pythonPath,
    required this.tempDir,
  });

  void installRequires(List<String> pythonRequires, {bool echo = true}) {
    if (echo) print("Installing requirements...");
    String tempPythonRequireFile = path.join(tempDir, "requirements.txt");
    File(tempPythonRequireFile).writeAsStringSync(pythonRequires.join("\n"));
    Process.runSync(
      pythonPath,
      ["-m", "pip", "install", "-r", tempPythonRequireFile],
    );
    File(tempPythonRequireFile).deleteSync();
    if (echo) print("Requirements installed.");
  }

  Future<void> runFile(
    String pythonFile, {
    List<String> arguments = const [],
    String? workingDirectory,
    ShellListener? listener,
    bool echo = true,
  }) async {
    if (!File(pythonFile).existsSync()) {
      throw FileSystemException("File does not exist or is not path!");
    }

    ShellListener newListener = listener ?? ShellListener();

    Process process = await Process.start(
        pythonPath, ["-u", pythonFile, ...arguments],
        mode: ProcessStartMode.normal,
        workingDirectory: defaultWorkingDirectory ?? workingDirectory);
    process.stdout.listen((event) {
      String message = String.fromCharCodes(event).trim();
      print(message);
      newListener.onMessage(message);
    }, onError: (e, s) {
      newListener.onError(e, s);
    }, onDone: newListener.onComplete);
    await process.exitCode;
  }

  Future<void> runString(String pythonCode,
      {String? workingDirectory,
      List<String> arguments = const [],
      ShellListener? listener,
      bool echo = true}) async {
    ShellListener newListener = listener ?? ShellListener();

    String tempPythonFile = path.join(tempDir,
        "${DateFormat("yyyy.MM.dd.HH.mm.ss").format(DateTime.now())}.py");
    File(tempPythonFile).writeAsStringSync(pythonCode);
    ShellListener listenerToSend = ShellListener(onMessage: (message) {
      newListener.onMessage(message);
    }, onError: (e, s) {
      File(tempPythonFile).deleteSync();
      newListener.onError(e, s);
    }, onComplete: () {
      File(tempPythonFile).deleteSync();
      newListener.onComplete();
    });

    await runFile(
      tempPythonFile,
      arguments: arguments,
      workingDirectory: workingDirectory,
      listener: listenerToSend,
      echo: echo,
    );
  }

  void remove() {
    Directory(path.join(config.instanceDir, name)).deleteSync(recursive: true);
  }
}
