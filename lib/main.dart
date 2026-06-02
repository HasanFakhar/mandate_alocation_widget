import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/mandate_controller.dart';
import 'widgets/mandate_allocation_widget.dart';

void main() {
  Get.put(MandateController());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 49, 82), // Azure
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A1A), // Very dark grey
          surfaceContainerLow: const Color(0xFF2A2A2A), // Dark grey
          outlineVariant: const Color.fromARGB(255, 74, 74, 74), // Medium grey
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 0, 49, 82), // Azure
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Mandate Allocation'),
          shadowColor: const Color.fromARGB(255, 0, 49, 82), // Azure
        ),

        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: MandateAllocationWidget(),
        ),
      ),
    );
  }
}