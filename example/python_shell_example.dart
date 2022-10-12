import "package:python_shell/python_shell.dart";
import 'package:python_shell/src/shell_listener.dart';

void main() async {
    var shell = PythonShell();
    await shell.initialize();

    shell.runString("""
import os

print(os.path.dirname(os.path.realpath(__file__)))
""", listener: ShellListener(
    completeCallback: () {
        print("finished");
    }
));
}
