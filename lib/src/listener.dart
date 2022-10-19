
import "listener.callbacks.dart";


/// PythonShell Listener Class
/// parameters and properties:
/// * [onMessage]: same as messageCallback
/// * [onError]: same as errorCallback
/// * [onComplete]: same as completeCallback
class ShellListener {
    Function(String) onMessage;
    Function(Object, StackTrace) onError;
    Function() onComplete;

    ShellListener({
        Function(String)? onMessage, Function(Object, StackTrace)? onError, Function()? onComplete
    }): onMessage = onMessage ?? emptyMessageCallback, onError = onError ?? emptyErrorCallback, onComplete = onComplete ?? emptyCompleteCallback;
}
