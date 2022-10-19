## 0.0.1
- Initial version.

<br />

## 0.0.2
- add 'ShellListener' class
- remove 'waitUntil' parameter.
- merge 'onMessage', 'onError', 'onComplete' parameters to 'ShellListener' parameter.
- check 'defaultPythonPath' exists when initialize.
- check pip can execute when initialize.

<br />

## 0.0.3
- change 'createInstance' parameter to 'useInstance' parameter.
- add 'instanceName' parameter.
- change default virtual environment path from 'defaultEnv' to 'instances/default'.
- 'clear' function now removes only instances except default.
- 'runString' function now creates a temporary file in the 'instanceDir/temp' when using instance.

<br />

## 0.0.4
- remove 'flutter' dependencies from 'pubspec'(for pub informations)
- 'clear' function now removes sub directories, files from 'temp' not removes itself.

<br />

## 0.0.5
- Recognize the 'createDefaultInstance' parameter normally.
- Now 'default' instance uses the temp folder.
- Fixing bugs that occur in windows.

<br />

## 0.0.6
- change python_shell app directory to '.python_shell.dart'
- move 'test.py' file into 'test' directory and fix test.dart file
- add logs.

<br />

## 0.0.7
- change directionality of library.
- add 'ShellManager', 'ShellInstance'.
- update 'README.md'
