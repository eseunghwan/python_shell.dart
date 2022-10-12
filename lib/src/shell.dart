
import "dart:io";
import "package:path/path.dart" as path;
import "package:intl/intl.dart";

import "utils.dart";
import 'shell_listener.dart';


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

/// PythonShell Class
/// * [shellConfig]: PythonShellConfig instance
/// * [createDefaultEnv]: flag for create default environment or not
class PythonShell {
    bool createDefaultEnv;
    PythonShellConfig config;

    PythonShell({PythonShellConfig? shellConfig, this.createDefaultEnv = false }): config = shellConfig ?? PythonShellConfig();

    Future<void> initialize({ bool? createDefaultEnv }) async {
        await initializeApp(config, createDefaultEnv ?? this.createDefaultEnv);
    }

    Future<Process> runFile(String pythonFile, { String? workingDirectory, bool createInstance = false, bool echo = true, ShellListener? listener }) async {
        listener = listener ?? ShellListener();
        Process process;

        if (createInstance) {
            var instanceMaps = createShellInstance(config);
            process = await Process.start(instanceMaps["python"]!, [ "-u", pythonFile ], mode: ProcessStartMode.detachedWithStdio, workingDirectory: config.defaultWorkingDirectory ?? workingDirectory);
            
            if (echo) {
                process.stdout.listen(
                    (event) {
                        String message = String.fromCharCodes(event).trim();
                        print(message);
                        listener!.onMessage(message);
                    },
                    onError: listener.onError,
                    onDone: listener.onComplete
                );
            }
            else {
                process.stdout.listen(
                    (event) {
                        listener!.onMessage(String.fromCharCodes(event).trim());
                    },
                    onError: listener.onError,
                    onDone: listener.onComplete
                );
            }
        }
        else {
            process = await Process.start(config.defaultPythonEnvPath!, [ "-u", pythonFile ], mode: ProcessStartMode.detachedWithStdio, workingDirectory: config.defaultWorkingDirectory ?? workingDirectory, runInShell: true);

            if (echo) {
                process.stdout.listen(
                    (event) {
                        String message = String.fromCharCodes(event).trim();
                        print(message);
                        listener!.onMessage(message);
                    },
                    onError: listener.onError,
                    onDone: listener.onComplete
                );
            }
            else {
                process.stdout.listen(
                    (event) {
                        listener!.onMessage(String.fromCharCodes(event).trim());
                    },
                    onError: listener.onError,
                    onDone: listener.onComplete
                );
            }
        }

        return process;
    }

    Future<Process> runString(String pythonCode, { bool createInstance = false, bool echo = true, ShellListener? listener }) async {
        String tempPythonFile = path.join(config.tempDir!, "${DateFormat("yyyy.MM.dd.HH.mm.ss").format(DateTime.now())}.py");
        File(tempPythonFile).writeAsStringSync(pythonCode);

        listener = listener ?? ShellListener();
        ShellListener newListener = ShellListener(
            messageCallback: listener.onMessage,
            errorCallback: (e, s) {
                listener!.onError(e, s);
                File(tempPythonFile).deleteSync();
            },
            completeCallback: () {
                listener!.onComplete();
                File(tempPythonFile).deleteSync();
            }
        );

        return await runFile(
            tempPythonFile, createInstance: createInstance, echo: echo, listener: newListener
        );
    }

    void clear() {
        Directory(config.instanceDir!).deleteSync(recursive: true);
        Directory(config.instanceDir!).createSync();
    }
}
