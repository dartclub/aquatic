import 'dart:async';

class AquaticLogger {
  final StreamController _controller = StreamController<String>();

  Stream<String> get stream => _controller.stream.cast<String>();

  String _convertMessage(String message) => message.trim().contains('\n')
      ? message.trim().replaceAll('\n', '\n\t\t')
      : message;

  void error(String message) {
    _controller.sink.add(
        '\x1b[41;39;1m[error]\x1b[31;49m:\t${_convertMessage(message)}\x1b[m');
  }

  void warn(String message) {
    _controller.sink.add(
        '\x1b[43;39;1m[warning]\x1b[33;49m:\t${_convertMessage(message)}\x1b[m');
  }

  void log(String message) {
    _controller.sink
        .add('\x1b[39;1m[log]\x1b[m:\t\t${_convertMessage(message)}');
  }
}
