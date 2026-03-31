import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/body_profile_model.dart';

class BodyAnalysisService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.single),
  );

  Future<BodyProfile> analyzeFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final poses = await _poseDetector.processImage(inputImage);

    if (poses.isEmpty) {
      throw Exception(
        'No person detected. Please ensure your full body is visible.',
      );
    }

    return _calculateBodyProfile(poses.first);
  }

  Future<BodyProfile> analyzeFromBytes({
    required Uint8List bytes,
    required ui.Size imageSize,
    required InputImageRotation rotation,
  }) async {
    // Determine correct format based on platform
    const format = InputImageFormat.nv21;

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: imageSize.width.toInt(),
      ),
    );

    final poses = await _poseDetector.processImage(inputImage);

    if (poses.isEmpty) {
      throw Exception(
        'No person detected. Stand 6 feet away with full body visible.',
      );
    }

    return _calculateBodyProfile(poses.first);
  }

  BodyProfile _calculateBodyProfile(Pose pose) {
    final landmarks = pose.landmarks;

    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      throw Exception(
        'Could not detect key body points. '
        'Please ensure good lighting and full body is visible.',
      );
    }

    final shoulderWidth = _distance(leftShoulder, rightShoulder);
    final hipWidth = _distance(leftHip, rightHip);

    // Estimate waist ratio from shoulder-to-hip geometry
    final torsoHeight = _distance(leftShoulder, leftHip);
    final waistRatio = torsoHeight > 0
        ? (min(shoulderWidth, hipWidth) / max(shoulderWidth, hipWidth))
        : 0.8;

    final bodyType = _determineBodyType(shoulderWidth, hipWidth, waistRatio);

    return BodyProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bodyType: bodyType,
      shoulderWidth: double.parse(shoulderWidth.toStringAsFixed(1)),
      hipWidth: double.parse(hipWidth.toStringAsFixed(1)),
      torsoLength: 0.0, // Not calculated in this method
      legLength: 0.0, // Not calculated in this method
      armLength: 0.0, // Not calculated in this method
      analyzedAt: DateTime.now(),
    );
  }

  double _distance(PoseLandmark a, PoseLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  String _determineBodyType(
    double shoulder,
    double hip,
    double waistRatio,
  ) {
    if (shoulder > hip * 1.1) return 'Inverted Triangle';
    if (hip > shoulder * 1.1) return 'Pear';
    if ((shoulder - hip).abs() < shoulder * 0.08 && waistRatio < 0.78) {
      return 'Hourglass';
    }
    if ((shoulder - hip).abs() < shoulder * 0.08 && waistRatio > 0.85) {
      return 'Rectangle';
    }
    return 'Apple';
  }

  void dispose() {
    _poseDetector.close();
  }
}
