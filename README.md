<h1 align="center">
    <br />
    python_shell
</h1>
<h3 align="center">
    Python Environment Manager and Executor for dart and flutter
    <br />
    <br />
</h3>
<br />

Available for:
- dart, flutter


Supported Platforms:
- Windows 10+ (x86, amd64, arm64)
- Linux Distos (amd64, arm64)
- OSX 11+ (amd64, arm64)

<br />
<hr>
<br />
<br />

# Install
- add via cli
```iterm
flutter(dart) pub add python_shell
```
- add dependency to 'pubspec.yaml'
```yaml
dependencies:
    [other dependencies...]

    python_shell:
        git:
            url: git://github.com/eseunghwan/python_shell.dart.git
            ref: master
```

<br /><br />

# Usage
- basic usage
```dart
import "package:python_shell/python_shell.dart";

var shell = PythonShell();
await shell.initialize();

await shell.runString("{pythonCode}");
```
- use instance
```dart
import "package:python_shell/python_shell.dart";

PythonShell().initialize();
var instance = ShellManager.getInstance("default");
await instance.runString("{pythonCode}");
```
<br />

- onMessage, onError, onComplete
```dart
// setups like above ...
shell.runString(
    "{pythonCode}",
    listener: ShellListener(
        onMessage: (message) {
            // if `echo` is `true`, log to console automatically
            print("message!");
        },
        onError: (e, s) {
            print("error!");
        },
        onComplete: () {
            print("complete!");
        }
    )
);
```

<br />

for further informations, refers to [python_shell.dart](https://github.com/eseunghwan/python_shell.dart/blob/master/lib/src/python_shell.dart)
