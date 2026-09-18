import 'package:image_picker/image_picker.dart';

/// Where a picture may come from. Shop photos allow both; identity captures
/// (CNIC front, CNIC back, liveness selfie) are camera-only, so the gallery
/// is never offered for them.
enum MediaSource { camera, gallery }

/// The boundary in front of the camera and gallery.
abstract interface class MediaCaptureService {
  /// A shop photo, from either source.
  Future<String?> pickShopImage(MediaSource source);

  /// An identity capture. Camera only, by design.
  Future<String?> captureIdentityImage({bool frontCamera = false});
}

class DeviceMediaCaptureService implements MediaCaptureService {
  DeviceMediaCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickShopImage(MediaSource source) async {
    final file = await _picker.pickImage(
      source: source == MediaSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 80,
    );
    return file?.path;
  }

  @override
  Future<String?> captureIdentityImage({bool frontCamera = false}) async {
    final file = await _picker.pickImage(
      // Always the camera: an identity document or liveness selfie is never
      // chosen from the gallery.
      source: ImageSource.camera,
      preferredCameraDevice: frontCamera
          ? CameraDevice.front
          : CameraDevice.rear,
      imageQuality: 80,
    );
    return file?.path;
  }
}

/// Returns a fixed path without touching the platform, so the wizard can be
/// walked in tests and on an emulator with no camera.
class FakeMediaCaptureService implements MediaCaptureService {
  FakeMediaCaptureService({this.path = '/mock/capture.jpg'});

  final String path;
  final List<String> calls = [];

  @override
  Future<String?> pickShopImage(MediaSource source) async {
    calls.add('shop:${source.name}');
    return path;
  }

  @override
  Future<String?> captureIdentityImage({bool frontCamera = false}) async {
    calls.add('identity:${frontCamera ? 'front' : 'rear'}');
    return path;
  }
}
