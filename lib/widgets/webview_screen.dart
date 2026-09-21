import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({super.key, required this.controller});

  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}
