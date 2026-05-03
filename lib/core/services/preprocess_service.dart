import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:urla/data/runtime/models/preprocess_task.dart';

class PreprocessService {
  static const int inputSize = 640;

  /// Full preprocessing pipeline: YUV→RGB + resize + normalise.
  ///
  /// [task] contains raw camera planes. All heavy work runs off the UI thread.
  Float32List preprocess(RawPreprocessTask task) {
    // 1. Convert YUV planes to tightly‑packed RGB bytes
    final Uint8List rgbBytes = _yuv420ToRgb(
      task.planes,
      task.width,
      task.height,
      task.bytesPerRow,
      task.bytesPerPixel,
    );

    // 2. Decode RGB bytes into an image object
    final image = img.Image.fromBytes(
      width: task.width,
      height: task.height,
      bytes: rgbBytes.buffer,
      order: img.ChannelOrder.rgb,
    );

    // 3. Resize to model input size
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // 4. Normalise 0–255 → 0–1 and write to Float32List
    final tensor = Float32List(inputSize * inputSize * 3);
    int index = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        tensor[index++] = pixel.r / 255.0;
        tensor[index++] = pixel.g / 255.0;
        tensor[index++] = pixel.b / 255.0;
      }
    }
    return tensor;
  }

  /// Convert YUV420 (planar or semi‑planar) to interleaved RGB.
  ///
  /// Handles both standard planar (3 separate planes) and NV12/NV21 where
  /// U and V are interleaved (bytesPerPixel == 2).
  static Uint8List _yuv420ToRgb(
    List<Uint8List> planes,
    int width,
    int height,
    List<int> bytesPerRow,
    List<int?> bytesPerPixel,
  ) {
    final Uint8List yPlane = planes[0];
    final Uint8List uPlane = planes[1];
    final Uint8List vPlane = planes.length > 2 ? planes[2] : planes[1];
    final bool interleavedUV = (bytesPerPixel[1] ?? 1) == 2;

    final int yRowStride = bytesPerRow[0];
    final int uvRowStride = bytesPerRow[1];
    final int uvPixelStride = interleavedUV ? 2 : 1;

    final Uint8List rgb = Uint8List(width * height * 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;
        final int yVal = yPlane[yIndex];

        int uVal, vVal;

        if (interleavedUV) {
          // NV12/NV21: U and V interleaved, UV plane is same as U plane.
          // For NV12, U comes first, then V.
          final int uvIndex = uvRowStride * (y ~/ 2) + (x ~/ 2) * 2;
          uVal = uPlane[uvIndex] - 128;
          vVal = uPlane[uvIndex + 1] - 128;
        } else {
          // Standard planar: separate U and V planes.
          final int uvIndex = uvRowStride * (y ~/ 2) + (x ~/ 2) * uvPixelStride;
          uVal = uPlane[uvIndex] - 128;
          vVal = vPlane[uvIndex] - 128;
        }

        // ITU‑R BT.601
        int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
        int g = (yVal - 0.344 * uVal - 0.714 * vVal).round().clamp(0, 255);
        int b = (yVal + 1.772 * uVal).round().clamp(0, 255);

        final int rgbIndex = (y * width + x) * 3;
        rgb[rgbIndex] = r;
        rgb[rgbIndex + 1] = g;
        rgb[rgbIndex + 2] = b;
      }
    }
    return rgb;
  }
}