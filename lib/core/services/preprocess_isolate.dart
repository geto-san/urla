import 'dart:isolate';
import 'dart:typed_data';

import 'package:urla/data/runtime/models/preprocess_task.dart';

import 'preprocess_service.dart';


/// Runs preprocessing in a background isolate.
///
/// All heavy CPU operations:
///   - YUV→RGB conversion
///   - image resize
///   - pixel normalization
///   are moved off the UI thread.
class PreprocessIsolate {
  late Isolate _isolate;
  late SendPort _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  /// Start the isolate and get the communication send port.
  Future<void> start() async {
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _receivePort.sendPort,
    );
    _sendPort = await _receivePort.first;
  }

  /// Send a raw camera frame to the isolate for preprocessing.
  Future<Float32List> process(RawPreprocessTask task) async {
    final response = ReceivePort();
    _sendPort.send([
      task,
      response.sendPort,
    ]);
    return await response.first as Float32List;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  /// Entry point for the isolate.
  static void _isolateEntry(SendPort mainSendPort) {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);

    final preprocess = PreprocessService();

    port.listen((message) {
      final RawPreprocessTask task = message[0];
      final SendPort replyPort = message[1];

      final tensor = preprocess.preprocess(task);
      replyPort.send(tensor);
    });
  }
}