// lib/main.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:frontend/screens/avatar_chat_screen.dart';
// Add these imports
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';



void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WebView platform
  late final PlatformWebViewControllerCreationParams params;
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  } else {
    params = const PlatformWebViewControllerCreationParams();
  }

  WebViewController.fromPlatformCreationParams(params);

  // Set platform-specific WebView implementations
  late final WebViewPlatform platform;
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    platform = WebKitWebViewPlatform();
  } else {
    platform = AndroidWebViewPlatform();
  }
  WebViewPlatform.instance = platform;

  runApp(const AvatarChatApp());
}


class AvatarChatApp extends StatelessWidget {
  const AvatarChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talking Avatar Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AvatarChatScreen(),
    );
  }
}