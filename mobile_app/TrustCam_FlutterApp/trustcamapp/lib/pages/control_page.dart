import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("System Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: ApiService.startSystem,
              child: const Text("Start System"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: ApiService.stopSystem,
              child: const Text("Stop System"),
            ),
          ],
        ),
      ),
    );
  }
}
