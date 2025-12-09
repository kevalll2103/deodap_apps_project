import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceScreen extends StatefulWidget {
  const FaceScreen({super.key});

  @override
  State<FaceScreen> createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  CameraController? _cameraController;
  CameraDescription? _frontCamera;

  late FaceDetector _faceDetector;

  bool _isInitialized = false;
  bool _isDetecting = false;
  List<Face> _faces = [];

  @override
  void initState() {
    super.initState();
    _initCameraAndMlKit();
  }

  Future<void> _initCameraAndMlKit() async {
    try {
      // 1. Get available cameras
      final cameras = await availableCameras();

      // Choose front camera if available
      _frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // 2. Initialize camera controller
      _cameraController = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // 3. Initialize ML Kit face detector
      final options = FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
        enableClassification: true, // smiling / eye open probabilities
        performanceMode: FaceDetectorMode.fast,
      );

      _faceDetector = FaceDetector(options: options);

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // 4. Start image stream
      await _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Error initializing camera/ML Kit: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    if (!_isInitialized || _cameraController == null) return;

    _isDetecting = true;

    try {
      final rotation = _frontCamera?.sensorOrientation ?? 0;
      final inputImage = _convertCameraImage(image, rotation);

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _faces = faces;
      });
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Convert [CameraImage] to [InputImage] for ML Kit.
  /// NOTE: Updated for new google_mlkit_commons:
  /// - NO InputImagePlaneMetadata
  /// - InputImageMetadata requires bytesPerRow only (from first plane)
  InputImage _convertCameraImage(CameraImage image, int rotation) {
    // 1. Concatenate all bytes from image planes
    final ui.WriteBuffer allBytes = ui.WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 2. Build metadata (no planeData anymore)
    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(rotation) ??
            InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    // 3. Create InputImage
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final previewSize = _cameraController!.value.previewSize!;
    // Camera preview is rotated; swap width/height
    final cameraImageSize = Size(previewSize.height, previewSize.width);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detection (ML Kit)'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: FacePainter(
                  faces: _faces,
                  imageSize: cameraImageSize,
                  widgetSize:
                      Size(constraints.maxWidth, constraints.maxHeight),
                ),
              );
            },
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_faces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No face detected',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    final face = _faces.first;

    final smileProb = face.smilingProbability;
    final leftEyeOpen = face.leftEyeOpenProbability;
    final rightEyeOpen = face.rightEyeOpenProbability;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Faces detected: ${_faces.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (smileProb != null)
            Text(
              'Smile: ${(smileProb * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white),
            ),
          if (leftEyeOpen != null && rightEyeOpen != null)
            Text(
              'Eyes open → L: ${(leftEyeOpen * 100).toStringAsFixed(1)}% | '
              'R: ${(rightEyeOpen * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size widgetSize;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.widgetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.greenAccent;

    for (final face in faces) {
      final rect = _scaleRect(
        rect: face.boundingBox,
        imageSize: imageSize,
        widgetSize: widgetSize,
      );
      canvas.drawRect(rect, paint);
    }
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
  }) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.widgetSize != widgetSize;
  }
}
