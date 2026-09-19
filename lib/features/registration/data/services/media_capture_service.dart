import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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

  /// The app declares the CAMERA permission for the QR scanner, which makes
  /// it mandatory for the camera intent as well. Asking first turns a hard
  /// failure into a decision the partner makes.
  Future<bool> _cameraAllowed() async =>
      (await Permission.camera.request()).isGranted;

  @override
  Future<String?> pickShopImage(MediaSource source) async {
    if (source == MediaSource.camera && !await _cameraAllowed()) return null;
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
    if (!await _cameraAllowed()) return null;
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
