import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../data/domain/models/frame_data.dart';

class FramePreprocessor {
  static const int modelInputSize = 640;
  late Isolate _isolate;
  late SendPort _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  Future<void> start() async {
    _isolate = await Isolate.spawn(_entryPoint, _receivePort.sendPort);
    _sendPort = await _receivePort.first;
  }

  Future<Float32List> process(FrameData frame) async {
    final response = ReceivePort();
    _sendPort.send([frame, response.sendPort]);
    return await response.first as Float32List;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  static void _entryPoint(SendPort mainSendPort) {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);
    port.listen((message) {
      final FrameData frame = message[0];
      final SendPort replyPort = message[1];
      replyPort.send(_preprocess(frame));
    });
  }

  static Float32List _preprocess(FrameData frame) {
    final image = img.Image.fromBytes(
      width: frame.width,
      height: frame.height,
      bytes: frame.bytes.buffer,
      order: img.ChannelOrder.rgb,
    );
    final resized = img.copyResize(image,
        width: modelInputSize, height: modelInputSize,
        interpolation: img.Interpolation.linear);
    final tensor = Float32List(modelInputSize * modelInputSize * 3);
    int index = 0;
    for (int y = 0; y < modelInputSize; y++) {
      for (int x = 0; x < modelInputSize; x++) {
        final pixel = resized.getPixel(x, y);
        tensor[index++] = pixel.r / 255.0;
        tensor[index++] = pixel.g / 255.0;
        tensor[index++] = pixel.b / 255.0;
      }
    }
    print('Tensor length: ${tensor.length}');   // should be 1228800
    return tensor;
  }
}