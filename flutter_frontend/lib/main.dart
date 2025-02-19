import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
//import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'widgets/avatar_controls.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register the platform view with updated configuration
  ui_web.platformViewRegistry.registerViewFactory(
    'web-view',
    (int viewId) => web.HTMLIFrameElement()
      ..src = 'http://localhost:3000'
      ..style.border = 'none'
      ..style.height = '100%'
      ..style.width = '100%'
      ..allow = 'autoplay; clipboard-write; encrypted-media; picture-in-picture'
      ..allowFullscreen = true
      ..setAttribute('crossorigin', 'anonymous'), // Add crossorigin attribute
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avatar Control Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Control Panel'),
      ),
      body: const SingleChildScrollView(
        child: AvatarControls(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String viewID = 'web-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presentation Delivery'),
      ),
      body: HtmlElementView(viewType: viewID),
    );
  }
}