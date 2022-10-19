import "package:python_shell/python_shell.dart";
import "package:test/test.dart";
import "dart:io";

void main() {
    group("python-shell tests", () {
        final PythonShell shell = PythonShell(PythonShellConfig());

        setUpAll(() async {
            // Additional setup goes here.
            await shell.initialize();
        });

        test("runString", () async {
            await shell.runString("print('in python!')");
        });

        test("runFile", () async {
            var pythonFile = File("test/test.py");
            pythonFile.writeAsStringSync("print('in python!')");
            await shell.runFile(pythonFile.path);
        });

        test("runString with new instance", () async {
            var instance = ShellManager.createInstance();
            await shell.runString("print('in python!')", instance: instance);
            instance.remove();
        });

        test("runFile with new instance", () async {
            var pythonFile = File("test/test.py");
            pythonFile.writeAsStringSync("print('in python!')");
            var instance = ShellManager.createInstance();
            await shell.runFile(pythonFile.path, instance: instance);
            instance.remove();
        });

        tearDownAll(() {
            print("test over");
            // shell.clear();
        });
    });
}
