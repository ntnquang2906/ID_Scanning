import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Need camera permission")));
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController =
          CameraController(_cameras[0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });

      _cameraController?.startImageStream((image) async {
        if (!isBlocked) {
          isBlocked = true;
          await _takePictureAndScan();
        }
      });
    }
  }

  Future<void> _takePictureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      isBlocked = false;
      return;
    }

    try {
      await _cameraController!.takePicture().then((XFile file) async {
        final File imageFile = File(file.path);
        await _scanText(imageFile);
      });
    } catch (e) {
      isBlocked = false;
      if (kDebugMode) {
        print("Take picture error: $e");
      }
    }
  }

   Future<void> _scanText(File imageFile) async {
  final inputImage = InputImage.fromFile(imageFile);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText =
      await textRecognizer.processImage(inputImage);
  final rawText = recognizedText.text.toUpperCase();

  if (rawText.contains('DRIVER LICENCE') &&
      rawText.contains('LICENCE NO') &&
      rawText.contains('DATE OF BIRTH')) {
    
    final entityExtractor = EntityExtractor(language: EntityExtractorLanguage.english);
    final extractedEntities = await entityExtractor.annotateText(rawText);
    
    Map<String, String> extractedData = {};

    for (final entity in extractedEntities) {
      for (final annotation in entity.entities) {
        switch (annotation.type) {
          case EntityType.address:
            extractedData['Address'] = entity.text;
            break;
          case EntityType.dateTime:
            extractedData['DOB'] = entity.text;
            break;
          default:
            break;
        }
      }
    }

    // Extract License Number using Regex
    RegExp licenseRegExp = RegExp(r'\b\d{1} \d{3} \d{3} \d{3}\b');
    Match? match = licenseRegExp.firstMatch(rawText);
    if (match != null) {
      extractedData['License Number'] = match.group(0)!;
    }

    // Extract Name using Regex (Assuming Name is in "LASTNAME FIRSTNAME" Format)
    RegExp nameRegExp = RegExp(r'^[A-Z]+ [A-Z]+$', multiLine: true);
    Iterable<Match> nameMatches = nameRegExp.allMatches(rawText);
    if (nameMatches.isNotEmpty) {
      extractedData['Name'] = nameMatches.first.group(0)!;
    }

    textRecognizer.close();
    entityExtractor.close();
    
    Navigator.pop(context, extractedData);
  }
  isBlocked = false;
}

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan ID"),
      ),
      body: Column(
        children: [
          _isCameraInitialized
              ? CameraPreview(_cameraController!)
              : Container(height: 200, color: Colors.black),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
