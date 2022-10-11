import "package:python_shell/python_shell.dart";

void main() async {
    var shell = PythonShell();
    await shell.initializeShell();

    shell.runString("""
import os

print(os.path.dirname(os.path.realpath(__file__)))
""", onComplete: () { print("finished"); });
}
