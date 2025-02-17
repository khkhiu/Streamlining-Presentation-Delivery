import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
//import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

void main() {
  // Register the platform view
  ui_web.platformViewRegistry.registerViewFactory(
    'web-view',
    (int viewId) => web.HTMLIFrameElement()
      ..src = 'http://localhost:3000'
      ..style.border = 'none'
      ..style.height = '100%'
      ..style.width = '100%',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Frontend',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
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