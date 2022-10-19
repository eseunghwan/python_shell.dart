import "package:python_shell/python_shell.dart";

void main() async {
    // 현재 스타일
//     var shell = PythonShell(shellConfig: PythonShellConfig(
//         pythonRequires: [ "PySide6" ],
//         defaultWorkingDirectory: "example"
//     ));
//     await shell.initialize();

//     await shell.runString("""
// import os, PySide6

// print("in python: ", os.getcwd())
// print("in python: ", PySide6)
// """, useInstance: true, instanceName: "testInstance1", listener: ShellListener(
//         completeCallback: () {
//             print(shell.resolved);
//             // shell.clear();
//         }
//     ));

    var shell = PythonShell(PythonShellConfig());
    await shell.initialize();

    var instance = ShellManager.getInstance("default");
    instance.installRequires([ "PySide6" ]);
    await instance.runString("""
import os, PySide6

print("in python: ", os.getcwd())
print("in python: ", PySide6)
""", echo: true);

    print("finished");
}
