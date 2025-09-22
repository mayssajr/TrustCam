import 'package:flutter/material.dart';

class DetectionCard extends StatelessWidget {
  final String imageUrl;
  final String timestamp;
  final String ipfsCid;
  const DetectionCard({super.key, required this.imageUrl, required this.timestamp, required this.ipfsCid,});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Detected intrusion at $timestamp",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                if (ipfsCid.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final url = "https://ipfs.io/ipfs/$ipfsCid";
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Open in browser: $url")),
                      );
                    },
                    child: Text(
                      "IPFS CID: $ipfsCid",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          decoration: TextDecoration.underline),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}