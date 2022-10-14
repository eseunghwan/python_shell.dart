
import "dart:io";

import "package:intl/intl.dart";
import "package:path/path.dart" as path;

import "shell_listener.dart";
import "utils.dart";


/// PythonShell Class
/// * [shellConfig]: PythonShellConfig instance
/// * [createDefaultEnv]: flag for create default environment or not
class PythonShell {
    bool createDefaultEnv;
    PythonShellConfig config;
    final List<Process> _runningProcesses;

    PythonShell({PythonShellConfig? shellConfig, this.createDefaultEnv = false }): config = shellConfig ?? PythonShellConfig(), _runningProcesses = [];

    bool get resolved => _runningProcesses.isEmpty;

    void clear({ String instanceName = "default" }) {
        var instances = Directory(config.instanceDir!).listSync().whereType<Directory>().toList();
        instances.where(
            (instanceDir) => path.basename(instanceDir.path) != "default"
        ).forEach(
            (instanceDir) {
                if (instanceDir.existsSync()) {
                    instanceDir.deleteSync(recursive: true);
                }
            }
        );

        var temps = Directory(config.tempDir!).listSync();
        temps.whereType<Directory>().forEach((directory) {
            directory.deleteSync(recursive: true);
        });
        temps.whereType<File>().forEach((file) {
            file.deleteSync();
        });
    }

    Future<void> initialize({ bool? createDefaultEnv }) async {
        await initializeApp(config, createDefaultEnv ?? this.createDefaultEnv);
    }

    Future<Process> runFile(String pythonFile, { String? workingDirectory, bool useInstance = false, String? instanceName, bool echo = true, ShellListener? listener }) async {
        listener = listener ?? ShellListener();
        Process process;

        if (useInstance) {
            var instanceMaps = instanceName == null ? createShellInstance(config, instanceName: instanceName) : getShellInstance(config, instanceName);
            process = await Process.start(instanceMaps["python"]!, [ "-u", pythonFile ], mode: ProcessStartMode.detachedWithStdio, workingDirectory: config.defaultWorkingDirectory ?? workingDirectory);
            _runningProcesses.add(process);

            if (echo) {
                process.stdout.listen(
                    (event) {
                        String message = String.fromCharCodes(event).trim();
                        print(message);
                        listener!.onMessage(message);
                    },
                    onError: (e, s) {
                        _runningProcesses.remove(process);
                        if (instanceName == null && Directory(instanceMaps["dir"]!).existsSync()) {
                            Directory(instanceMaps["dir"]!).deleteSync(recursive: true);
                        }

                        listener!.onError(e, s);
                    },
                    onDone: () {
                        _runningProcesses.remove(process);
                        if (instanceName == null && Directory(instanceMaps["dir"]!).existsSync()) {
                            Directory(instanceMaps["dir"]!).deleteSync(recursive: true);
                        }

                        listener!.onComplete();
                    }
                );
            }
            else {
                process.stdout.listen(
                    (event) {
                        listener!.onMessage(String.fromCharCodes(event).trim());
                    },
                    onError: (e, s) {
                        _runningProcesses.remove(process);
                        if (instanceName == null && Directory(instanceMaps["dir"]!).existsSync()) {
                            Directory(instanceMaps["dir"]!).deleteSync(recursive: true);
                        }

                        listener!.onError(e, s);
                    },
                    onDone: () {
                        _runningProcesses.remove(process);
                        if (instanceName == null && Directory(instanceMaps["dir"]!).existsSync()) {
                            Directory(instanceMaps["dir"]!).deleteSync(recursive: true);
                        }

                        listener!.onComplete();
                    }
                );
            }
        }
        else {
            process = await Process.start(config.defaultPythonEnvPath!, [ "-u", pythonFile ], mode: ProcessStartMode.detachedWithStdio, workingDirectory: config.defaultWorkingDirectory ?? workingDirectory, runInShell: true);
            _runningProcesses.add(process);

            if (echo) {
                process.stdout.listen(
                    (event) {
                        String message = String.fromCharCodes(event).trim();
                        print(message);
                        listener!.onMessage(message);
                    },
                    onError: (e, s) {
                        _runningProcesses.remove(process);
                        listener!.onError(e, s);
                    },
                    onDone: () {
                        _runningProcesses.remove(process);
                        listener!.onComplete();
                    }
                );
            }
            else {
                process.stdout.listen(
                    (event) {
                        listener!.onMessage(String.fromCharCodes(event).trim());
                    },
                    onError: (e, s) {
                        _runningProcesses.remove(process);
                        listener!.onError(e, s);
                    },
                    onDone: () {
                        _runningProcesses.remove(process);
                        listener!.onComplete();
                    }
                );
            }
        }

        return process;
    }

    Future<Process> runString(String pythonCode, { bool useInstance = false, String? instanceName, bool echo = true, ShellListener? listener }) async {
        String tempPythonFileName = "${DateFormat("yyyy.MM.dd.HH.mm.ss").format(DateTime.now())}.py", tempPythonFile;
        if (useInstance) {
            if (instanceName != null && instanceName.toLowerCase() == "default") {
                tempPythonFile = path.join(config.tempDir!, tempPythonFileName);
            }
            else {
                var instanceMaps = instanceName == null ? createShellInstance(config) : getShellInstance(config, instanceName);
                tempPythonFile = path.join(instanceMaps["dir"]!, "temp", tempPythonFileName);
            }
        }
        else {
            tempPythonFile = path.join(config.tempDir!, tempPythonFileName);
        }
        File(tempPythonFile).writeAsStringSync(pythonCode);

        listener = listener ?? ShellListener();
        ShellListener newListener = ShellListener(
            messageCallback: listener.onMessage,
            errorCallback: (e, s) {
                listener!.onError(e, s);
                if (File(tempPythonFile).existsSync()) {
                    File(tempPythonFile).deleteSync();
                }
            },
            completeCallback: () {
                listener!.onComplete();
                if (File(tempPythonFile).existsSync()) {
                    File(tempPythonFile).deleteSync();
                }
            }
        );

        return await runFile(
            tempPythonFile, useInstance: useInstance, instanceName: instanceName, echo: echo, listener: newListener
        );
    }
}

/// PythonShell Configuration Class
/// * [defaultPythonPath]: Default python path to use
/// * [defaultPythonVersion]: Default python version to use
/// * [downloadPython]: (Windows Only!)Decide whether to download python
/// * [pythonRequireFile]: requirements(file) for python
/// * [pythonRequires]: requirements(list) for python
class PythonShellConfig {
    String defaultPythonPath;
    String defaultPythonVersion;
    bool downloadPython;

    String? appDir;
    String? tempDir;
    String? instanceDir;
    String? defaultWorkingDirectory;
    String? defaultPythonEnvPath;
    String? pythonRequireFile;
    List<String>? pythonRequires;

    PythonShellConfig({
        this.defaultPythonPath = "python3",
        this.defaultPythonVersion = "3.9.13",
        this.downloadPython = false,
        this.defaultWorkingDirectory,
        this.pythonRequireFile,
        this.pythonRequires
    }) {
        if ((Platform.isLinux || Platform.isMacOS)) {
            if (["python", "python2", "python3"].contains(defaultPythonPath)) {
                defaultPythonPath = "/usr/bin/$defaultPythonPath";
            }
            else if (!File(defaultPythonPath).existsSync()) {
                defaultPythonPath = "/usr/bin/python3";
            }
        }
    }
}

/// PythonShell Listener Class
/// arguments:
/// * [messageCallback]: callback for messages
/// * [errorCallback]: callback for error handle
/// * [completeCallback]: callback for shell finished
/// 
/// properties:
/// * [onMessage]: same as messageCallback
/// * [onError]: same as errorCallback
/// * [onComplete]: same as completeCallback
class ShellListener {
    Function(String) onMessage;
    Function(Object, StackTrace) onError;
    Function() onComplete;

    ShellListener({
        Function(String)? messageCallback, Function(Object, StackTrace)? errorCallback, Function()? completeCallback
    }): onMessage = messageCallback ?? emptyMessageCallback, onError = errorCallback ?? emptyErrorCallback, onComplete = completeCallback ?? emptyCompleteCallback;
}
