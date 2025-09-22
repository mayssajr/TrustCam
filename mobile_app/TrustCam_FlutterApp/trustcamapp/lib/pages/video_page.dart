import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..loadRequest(Uri.parse("http://192.168.1.136:5000/video/live"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live stream"),
        backgroundColor: const Color(0xFF6A11CB),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

}
