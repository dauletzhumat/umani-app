import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum ReceiptCaptureOutcome { captured, permissionDenied, cancelled }

class ReceiptCaptureResult {
  const ReceiptCaptureResult(this.outcome, {this.imagePath});

  final ReceiptCaptureOutcome outcome;
  final String? imagePath;
}

/// Abstracts camera capture so ReceiptScanScreen can be tested without a
/// real camera/device — same shape as VisionService/OpenAiClientService
/// (T4.4/T4.5) on the backend side. Uses image_picker's native camera UI
/// rather than the `camera` package's embedded live preview: a full
/// custom preview+overlay is untestable in this environment either way,
/// and image_picker already gives a working capture flow with far less
/// platform-channel surface area.
abstract class ReceiptCaptureService {
  Future<ReceiptCaptureResult> captureReceipt();
}

class ImagePickerReceiptCaptureService implements ReceiptCaptureService {
  const ImagePickerReceiptCaptureService();

  @override
  Future<ReceiptCaptureResult> captureReceipt() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.camera);
      if (file == null) {
        return const ReceiptCaptureResult(ReceiptCaptureOutcome.cancelled);
      }
      return ReceiptCaptureResult(
        ReceiptCaptureOutcome.captured,
        imagePath: file.path,
      );
    } on PlatformException catch (exception) {
      if (exception.code == 'camera_access_denied') {
        return const ReceiptCaptureResult(
          ReceiptCaptureOutcome.permissionDenied,
        );
      }
      rethrow;
    }
  }
}

final receiptCaptureServiceProvider = Provider<ReceiptCaptureService>((ref) {
  return const ImagePickerReceiptCaptureService();
});
