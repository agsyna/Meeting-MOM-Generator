import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling ONNX model operations
/// This service acts as a bridge between Dart and native ONNX Runtime
class OnnxService {
  static const platform = MethodChannel('com.example.meeting_gist/onnx');
  static const EventChannel eventChannel =
      EventChannel('com.example.meeting_gist/onnx_events');

  late Stream<dynamic> _progressStream;
  StreamSubscription<dynamic>? _progressSubscription;

  bool _isInitialized = false;
  String? _whisperModelPath;
  String? _diarizationModelPath;

  bool get isInitialized => _isInitialized;

  OnnxService() {
    _progressStream = eventChannel.receiveBroadcastStream();
  }

  /// Initialize ONNX models
  Future<bool> initialize({
    required String whisperModelPath,
    required String diarizationModelPath,
  }) async {
    try {
      _whisperModelPath = whisperModelPath;
      _diarizationModelPath = diarizationModelPath;

      final result = await platform.invokeMethod<bool>(
        'initializeModels',
        {
          'whisper_model': whisperModelPath,
          'diarization_model': diarizationModelPath,
        },
      );

      _isInitialized = result ?? false;
      debugPrint('ONNX models initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing ONNX models: $e');
      return false;
    }
  }

  /// Transcribe audio file using Whisper ONNX
  Future<Map<String, dynamic>?> transcribeAudio(String audioFilePath) async {
    if (!_isInitialized) {
      debugPrint('ONNX models not initialized');
      return null;
    }

    try {
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'transcribeAudio',
        {
          'audio_path': audioFilePath,
        },
      );

      if (result != null) {
        final castedResult = Map<String, dynamic>.from(result);
        debugPrint('Transcription completed: ${castedResult.length} segments');
        return castedResult;
      }

      return null;
    } catch (e) {
      debugPrint('Error transcribing audio: $e');
      return null;
    }
  }

  /// Perform speaker diarization using ONNX model
  Future<Map<String, dynamic>?> performDiarization(
    String audioFilePath,
    Map<String, dynamic> transcriptionResults,
  ) async {
    if (!_isInitialized) {
      debugPrint('ONNX models not initialized');
      return null;
    }

    try {
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'performDiarization',
        {
          'audio_path': audioFilePath,
          'transcription_results': transcriptionResults,
        },
      );

      if (result != null) {
        final castedResult = Map<String, dynamic>.from(result);
        debugPrint('Diarization completed');
        return castedResult;
      }

      return null;
    } catch (e) {
      debugPrint('Error performing diarization: $e');
      return null;
    }
  }

  /// Process audio with both transcription and diarization
  Future<Map<String, dynamic>?> processAudio(String audioFilePath) async {
    if (!_isInitialized) {
      debugPrint('ONNX models not initialized');
      return null;
    }

    try {
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'processAudio',
        {
          'audio_path': audioFilePath,
        },
      );

      if (result != null) {
        final castedResult = Map<String, dynamic>.from(result);
        debugPrint('Audio processing completed');
        return castedResult;
      }

      return null;
    } catch (e) {
      debugPrint('Error processing audio: $e');
      return null;
    }
  }

  /// Stream progress updates from native side
  void listenToProgress(Function(double) onProgressUpdate) {
    _progressSubscription = _progressStream.listen(
      (event) {
        if (event is double) {
          onProgressUpdate(event);
        } else if (event is num) {
          onProgressUpdate(event.toDouble());
        }
      },
      onError: (error) {
        debugPrint('Error in progress stream: $error');
      },
    );
  }

  /// Stop listening to progress
  void stopListeningToProgress() {
    _progressSubscription?.cancel();
  }

  /// Check if model files exist
  Future<bool> checkModelFiles() async {
    try {
      if (_whisperModelPath == null || _diarizationModelPath == null) {
        return false;
      }

      final whisperFile = File(_whisperModelPath!);
      final diarizationFile = File(_diarizationModelPath!);

      final whisperExists = await whisperFile.exists();
      final diarizationExists = await diarizationFile.exists();

      debugPrint('Whisper model exists: $whisperExists');
      debugPrint('Diarization model exists: $diarizationExists');

      return whisperExists && diarizationExists;
    } catch (e) {
      debugPrint('Error checking model files: $e');
      return false;
    }
  }

  /// Get models directory
  Future<String> getModelsDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');

      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      return modelsDir.path;
    } catch (e) {
      debugPrint('Error getting models directory: $e');
      rethrow;
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    try {
      stopListeningToProgress();
      await platform.invokeMethod<void>('cleanup');
      _isInitialized = false;
      debugPrint('ONNX service disposed');
    } catch (e) {
      debugPrint('Error disposing ONNX service: $e');
    }
  }
}
