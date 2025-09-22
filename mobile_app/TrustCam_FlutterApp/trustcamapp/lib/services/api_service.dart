import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.136:5000";

  // static Future<List<String>> getDetections(String cls) async {
  //   final response = await http.get(Uri.parse("$baseUrl/detections/$cls"));
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     return List<String>.from(data["images"]);
  //   } else {
  //     throw Exception("Erreur API: ${response.statusCode}");
  //   }
  // }

  static Future<List<Map<String, String>>> getDetectionsWithTimestamps(String cls) async {
    final response = await http.get(Uri.parse("$baseUrl/detections/$cls"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey("detections")) {
        List detections = data["detections"];
        return detections.map<Map<String, String>>((d) {
          return {
            "url": d["url"],
            "timestamp": d["timestamp"],
            "ipfs_cid": d["ipfs_cid"] ?? "",
          };
        }).toList();
      }

      if (data.containsKey("images")) {
        return List<String>.from(data["images"])
            .map<Map<String, String>>((url) => {"url": url, "timestamp": "", "ipfs_cid": "",})
            .toList();
      }

      throw Exception("Réponse inattendue de l'API");
    } else {
      throw Exception("Erreur API: ${response.statusCode}");
    }
  }

  static Future<void> startSystem() async {
    await http.get(Uri.parse("$baseUrl/control/start"));
  }

  static Future<void> stopSystem() async {
    await http.get(Uri.parse("$baseUrl/control/stop"));
  }
}
