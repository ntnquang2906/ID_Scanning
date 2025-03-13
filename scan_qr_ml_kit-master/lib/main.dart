import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'collect_registration/collect_registration.dart';

var logger = Logger(
  printer: PrettyPrinter(),
  filter: null,
  output: null,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ID Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CollectRegistration(),
    );
  }
}