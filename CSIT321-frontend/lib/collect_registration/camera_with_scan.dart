import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CameraWithScan extends StatefulWidget {
  final CameraDescription camera;

  const CameraWithScan({super.key, required this.camera});

  @override
  State<CameraWithScan> createState() => _CameraWithScanState();
}

class _CameraWithScanState extends State<CameraWithScan> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isDetecting = false;
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;
    _startIDDetection();
  }

  void _startIDDetection() {
    _controller.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;
      try {
        final inputImage = _convertCameraImage(image);
        final recognizedText = await _textRecognizer.processImage(inputImage);
        final extractedData = _extractIDData(recognizedText.text);

        if (extractedData.isNotEmpty) {
          final file = await _controller.takePicture();
          await _controller.stopImageStream();
          if (mounted) {
            Navigator.pop(context, {'file': file, ...extractedData});
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error detecting ID: $e');
        }
      } finally {
        _isDetecting = false;
      }
    });
  }

  InputImage _convertCameraImage(CameraImage cameraImage) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );

    final rotation = InputImageRotation.rotation0deg; // Adjust based on your camera orientation
    final format = InputImageFormat.yuv420;

    final planeData = cameraImage.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          width: cameraImage.width,
          height: cameraImage.height,
        );
      },
    ).toList();

    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: InputImageData(
        size: imageSize,
        imageRotation: rotation,
        inputImageFormat: format,
        planeData: planeData,
      ),
    );
  }

  Map<String, String> _extractIDData(String text) {
    final Map<String, String> extracted = {};
    final idPattern = RegExp(r'\b\d{6,10}\b'); // Adjust regex as needed
    final namePattern = RegExp(r'([A-Z][a-z]+)\s([A-Z][a-z]+)');
    final datePattern = RegExp(r'\b(\d{2}/\d{2}/\d{4})\b');

    final idMatch = idPattern.firstMatch(text);
    final nameMatch = namePattern.firstMatch(text);
    final dateMatches = datePattern.allMatches(text).toList();

    if (idMatch != null) extracted['idNumber'] = idMatch.group(0)!;
    if (nameMatch != null) {
      extracted['firstName'] = nameMatch.group(1)!;
      extracted['lastName'] = nameMatch.group(2)!;
    }
    if (dateMatches.length > 1) {
      extracted['dob'] = dateMatches[0].group(0)!;
      extracted['expiry'] = dateMatches[1].group(0)!;
    }
    return extracted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}