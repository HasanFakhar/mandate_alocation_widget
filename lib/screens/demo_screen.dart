import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/mandate_controller.dart';
import '../widgets/mandate_allocation_widget.dart';

void main() {
  Get.put(MandateController());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mandate Allocation')),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: MandateAllocationWidget(),
        ),
      ),
    );
  }
}