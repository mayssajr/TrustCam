import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/detection_card.dart';

class DetectionsPage extends StatefulWidget {
  const DetectionsPage({super.key});

  @override
  State<DetectionsPage> createState() => _DetectionsPageState();
}

class _DetectionsPageState extends State<DetectionsPage> {
  List<Map<String, String>> detections = [];

  Future<void> loadDetections() async {
    try {
      final data = await ApiService.getDetectionsWithTimestamps("person");
      setState(() => detections = data);
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadDetections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detections"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadDetections,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDetections,
        child: detections.isEmpty
            ? const Center(child: Text("No detection"))
            : ListView.builder(
          itemCount: detections.length,
          itemBuilder: (context, index) {
            return DetectionCard(
              imageUrl: detections[index]["url"]!,
              timestamp: detections[index]["timestamp"]!,
              ipfsCid: detections[index]["ipfs_cid"]!,
            );
          },
        ),
      ),
    );
  }
}
