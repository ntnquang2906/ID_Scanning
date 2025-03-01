import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_with_scan.dart';

class CollectRegistration extends StatelessWidget {
  final CameraDescription camera;

  const CollectRegistration({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect Registration'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CameraWithScan(camera: camera),
              ),
            );

            if (result != null) {
              _showScannedData(context, result);
            }
          },
          child: const Text('Scan ID'),
        ),
      ),
    );
  }

  void _showScannedData(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scanned ID Data'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('File: ${data['file'].path}'),
                Text('ID: ${data['id']}'),
                Text('Name: ${data['name']}'),
                Text('Date: ${data['date']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}