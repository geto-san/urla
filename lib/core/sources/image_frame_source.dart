import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../data/domain/models/frame_data.dart';

class ImageFrameSource implements FrameSource {
  final ImagePicker _picker = ImagePicker();
  final StreamController<FrameData> _controller =
      StreamController<FrameData>.broadcast();

  /// Holds the original file bytes for display, set after pick.
  Uint8List? lastRawBytes;

  @override
  Stream<FrameData> get frameStream => _controller.stream;

  @override
  Future<void> start() async {}   // not used

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  /// Trigger the image picker, then emit a single FrameData.
  /// The caller MUST already be listening to [frameStream] before calling this.
  Future<void> pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    lastRawBytes = await file.readAsBytes();
    final decoded = img.decodeImage(lastRawBytes!);
    if (decoded == null) return;

    final rgbBytes = Uint8List.fromList(
        decoded.getBytes(order: img.ChannelOrder.rgb));

    // Emit frame – the subscriber processes it and will dispose later.
    _controller.add(FrameData(
        bytes: rgbBytes, width: decoded.width, height: decoded.height));

    print('Decoded image: ${decoded.width}x${decoded.height}');
    print('RGB bytes length: ${rgbBytes.length}');   // width*height*3
  }
}