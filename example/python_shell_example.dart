import "package:python_shell/python_shell.dart";

void main() async {
    var shell = PythonShell(shellConfig: PythonShellConfig(
        pythonRequires: [ "PySide6" ],
        defaultWorkingDirectory: "example"
    ));
    await shell.initialize();

    await shell.runString("""
import os, PySide6

print("in python: ", os.getcwd())
print("in python: ", PySide6)
""", useInstance: true, instanceName: "testInstance1", listener: ShellListener(
        completeCallback: () {
            print(shell.resolved);
            // shell.clear();
        }
    ));
}
