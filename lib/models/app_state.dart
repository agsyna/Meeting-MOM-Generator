import 'package:flutter/foundation.dart';
import 'package:meeting_gist/models/transcription_result.dart';

/// Enum for different app states
enum AppStatus {
  idle,
  recording,
  processing,
  completed,
  error,
}

/// Centralized app state management
class AppState extends ChangeNotifier {
  AppStatus _status = AppStatus.idle;
  String _errorMessage = '';
  String? _audioPath;
  TranscriptionResult? _result;
  double _processingProgress = 0.0;
  String _statusMessage = '';

  // Getters
  AppStatus get status => _status;
  String get errorMessage => _errorMessage;
  String? get audioPath => _audioPath;
  TranscriptionResult? get result => _result;
  double get processingProgress => _processingProgress;
  String get statusMessage => _statusMessage;

  bool get isRecording => _status == AppStatus.recording;
  bool get isProcessing => _status == AppStatus.processing;
  bool get hasError => _status == AppStatus.error;
  bool get isCompleted => _status == AppStatus.completed;
  bool get isIdle => _status == AppStatus.idle;

  // Setters with notification
  void setStatus(AppStatus status) {
    _status = status;
    if (status != AppStatus.error) {
      _errorMessage = '';
    }
    notifyListeners();
  }

  void setError(String message) {
    _status = AppStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void setAudioPath(String path) {
    _audioPath = path;
    notifyListeners();
  }

  void setResult(TranscriptionResult result) {
    _result = result;
    _status = AppStatus.completed;
    _processingProgress = 1.0;
    notifyListeners();
  }

  void setProcessingProgress(double progress) {
    _processingProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  void reset() {
    _status = AppStatus.idle;
    _errorMessage = '';
    _audioPath = null;
    _result = null;
    _processingProgress = 0.0;
    _statusMessage = '';
    notifyListeners();
  }
}
