import "package:python_shell/python_shell.dart";
import "package:test/test.dart";
import "dart:io";

void main() {
    group("python-shell tests", () {
        final PythonShell shell = PythonShell(shellConfig: PythonShellConfig());

        setUpAll(() async {
            // Additional setup goes here.
            await shell.initialize();

            print(shell.config.defaultPythonPath);
            print(shell.config.defaultPythonVersion);
            print(shell.config.defaultPythonEnvPath);
            print(shell.config.pythonRequireFile);
            print(shell.config.pythonRequires);
            print("tests: \n");
        });

        test("runString", () async {
            await shell.runString("print('in python!')");
        });

        test("runFile", () async {
            var pythonFile = File("test.py");
            pythonFile.writeAsStringSync("print('in python!')");
            await shell.runFile(pythonFile.path);
        });

        test("runString with new instance", () async {
            await shell.runString("print('in python!')", useInstance: true);
        });

        test("runFile with new instance", () async {
            var pythonFile = File("test.py");
            pythonFile.writeAsStringSync("print('in python!')");
            await shell.runFile(pythonFile.path, useInstance: true);
        });

        tearDownAll(() {
            print("test over");
            // shell.clear();
        });
    });
}
