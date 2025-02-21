import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  List<String> _supportedLocales = ['en-US'];
  String _currentLocale = 'en-US';

  // Getters for the service state
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  List<String> get supportedLocales => _supportedLocales;
  String get currentLocale => _currentLocale;

  // Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }

    // Initialize the speech recognition
    _isInitialized = await _speech.initialize(
      onStatus: _onStatusChange,
      onError: _onError,
      debugLogging: kDebugMode,
    );

    if (_isInitialized) {
      // Get the list of supported languages
      final locales = await _speech.locales();
      _supportedLocales = locales
          .map((locale) => locale.localeId)
          .toList();
    }

    notifyListeners();
    return _isInitialized;
  }

  // Start listening for speech input
  Future<bool> startListening({
    String? selectedLocale,
    bool continuous = false,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    // Update the locale if specified
    if (selectedLocale != null && 
        _supportedLocales.contains(selectedLocale)) {
      _currentLocale = selectedLocale;
    }

    // Start the speech recognition
    _isListening = await _speech.listen(
      onResult: _onSpeechResult,
      listenMode: continuous 
          ? stt.ListenMode.dictation
          : stt.ListenMode.confirmation,
      localeId: _currentLocale,
    );

    notifyListeners();
    return _isListening;
  }

  // Stop listening for speech input
  Future<void> stopListening() async {
    _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  // Handle speech recognition results
  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    notifyListeners();
  }

  // Handle status changes in speech recognition
  void _onStatusChange(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      notifyListeners();
    }
  }

  // Handle errors in speech recognition
  void _onError(dynamic error) {
    _isListening = false;
    print('Speech recognition error: $error');
    notifyListeners();
  }

  // Clean up resources
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}