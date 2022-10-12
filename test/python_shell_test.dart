import "package:python_shell/python_shell.dart";
import "package:test/test.dart";
import "dart:io";

void main() {
    group("python-shell tests", () {
        final PythonShell shell = PythonShell(shellConfig: PythonShellConfig());

        setUp(() async {
            // Additional setup goes here.
            await shell.initialize();

            print(shell.config.defaultPythonPath);
            print(shell.config.defaultPythonVersion);
            print(shell.config.defaultPythonEnvPath);
            print(shell.config.pythonRequireFile);
            print(shell.config.pythonRequires);
            print("python results: \n");
        });

        test("runString", () {
            shell.runString("print(1234)");
        });

        test("runFile", () {
            var pythonFile = File("test.py");
            pythonFile.writeAsStringSync("print(1234)");
            shell.runFile(pythonFile.path);
        });
    });
}
