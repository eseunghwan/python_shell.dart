
import "dart:io";
import "package:path/path.dart" as path;
import "package:intl/intl.dart";

import "utils.dart";


/// PythonShell Configurations
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
    });
}

class PythonShell {
    bool createDefaultEnv;
    PythonShellConfig config;

    PythonShell({PythonShellConfig? shellConfig, this.createDefaultEnv = false }): config = shellConfig ?? PythonShellConfig();

    Future<void> initializeShell({ bool? createDefaultEnv }) async {
        await initializeApp(config, createDefaultEnv ?? this.createDefaultEnv);
    }

    Future<void> runFile(String pythonFile, { String? workingDirectory, bool createInstance = false, bool waitUntil = false, Function(String)? onMessage, Function(Object, StackTrace)? onError, Function()? onComplete, bool echo = true }) async {
        if (createInstance) {
            var instanceMaps = createShellInstance(config);
            if (waitUntil) {
                if (onMessage != null) {
                    print("If `echo` is true, `onMessage` is not invoked");
                }

                try {
                    Process.runSync(instanceMaps["python"]!, [ "-u", pythonFile ], workingDirectory: config.defaultWorkingDirectory ?? workingDirectory, runInShell: true);
                    if (onComplete != null) {
                        onComplete();
                    }
                }
                on Exception catch (e, s) {
                    if (onError != null) {
                        onError(e, s);
                    }
                }
            }
            else {
                var process = await Process.start(instanceMaps["python"]!, [ "-u", pythonFile ], mode: ProcessStartMode.detachedWithStdio, workingDirectory: config.defaultWorkingDirectory ?? workingDirectory);
                
                if (echo) {
                    process.stdout.listen(
                        (event) {
                            String message = String.fromCharCodes(event).trim();
                            print(message);
                            if (onMessage != null) {
                                onMessage(message);
                            }
                        },
                        onError: onError,
                        onDone: onComplete
                    );
                }
                else {
                    process.stdout.listen(
                        (event) {
                            if (onMessage != null) {
                                onMessage(String.fromCharCodes(event).trim());
                            }
                        },
                        onError: onError,
                        onDone: onComplete
                    );
                }
            }
        }
        else {
            if (waitUntil) {
                if (onMessage != null) {
                    print("If `echo` is true, `onMessage` is not invoked");
                }

                try {
                    Process.runSync(config.defaultPythonEnvPath!, [ "-u", pythonFile ], workingDirectory: config.defaultWorkingDirectory ?? workingDirectory, runInShell: true);
                    if (onComplete != null) {
                        onComplete();
                    }
                }
                on Exception catch (e, s) {
                    if (onError != null) {
                        onError(e, s);
                    }
                }
            }
            else {
                var process = await Process.start(config.defaultPythonEnvPath!, [ "-u", pythonFile ], mode: ProcessStartMode.detachedWithStdio, workingDirectory: config.defaultWorkingDirectory ?? workingDirectory, runInShell: true);

                if (echo) {
                    process.stdout.listen(
                        (event) {
                            String message = String.fromCharCodes(event).trim();
                            print(message);
                            if (onMessage != null) {
                                onMessage(message);
                            }
                        },
                        onError: onError,
                        onDone: onComplete
                    );
                }
                else {
                    process.stdout.listen(
                        (event) {
                            if (onMessage != null) {
                                onMessage(String.fromCharCodes(event).trim());
                            }
                        },
                        onError: onError,
                        onDone: onComplete
                    );
                }
            }
        }
    }

    Future<void> runString(String pythonCode, { bool createInstance = false, bool waitUntil = false, Function(String)? onMessage, Function(Object, StackTrace)? onError, Function()? onComplete, bool echo = true }) async {
        String tempPythonFile = path.join(config.tempDir!, "${DateFormat("yyyy.MM.dd.HH.mm.ss").format(DateTime.now())}.py");
        File(tempPythonFile).writeAsStringSync(pythonCode);
        await runFile(
            tempPythonFile, createInstance: createInstance, waitUntil: waitUntil, echo: echo, onMessage: onMessage,
            onError: (e, s) {
                if (onError != null) {
                    onError(e, s);
                }
                File(tempPythonFile).deleteSync();
            },
            onComplete: () {
                if (onComplete != null) {
                    onComplete();
                }
                File(tempPythonFile).deleteSync();
            }
        );
    }

    void clear() {
        Directory(config.instanceDir!).deleteSync(recursive: true);
        Directory(config.instanceDir!).createSync();
    }
}
