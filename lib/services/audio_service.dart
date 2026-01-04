import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Service for handling audio recording operations
class AudioService {
  late AudioRecorder _audioRecorder;
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  AudioService() {
    _audioRecorder = AudioRecorder();
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      return false;
    }
  }

  /// Start recording audio to WAV file
  Future<bool> startRecording() async {
    try {
      // Check permissions
      final hasPermission = await hasMicrophonePermission();
      if (!hasPermission) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          debugPrint('Microphone permission denied');
          return false;
        }
      }

      // Get application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${documentsDir.path}/recordings');

      // Create recordings directory if it doesn't exist
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${recordingsDir.path}/recording_$timestamp.wav';

      // Start recording in WAV format
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000, // 16 kHz for Whisper
          numChannels: 1, // Mono
          bitRate: 128000,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      debugPrint('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null && await File(path).exists()) {
        debugPrint('Recording stopped: $path');
        debugPrint(
            'File size: ${(await File(path).length()) / 1024 / 1024} MB');
        return path;
      }

      debugPrint('Recording stopped but file not found');
      return null;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      await _audioRecorder.stop();
      _isRecording = false;
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
      debugPrint('Recording cancelled');
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  /// Get all recorded files
  Future<List<File>> getRecordedFiles() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${documentsDir.path}/recordings');

      if (!await recordingsDir.exists()) {
        return [];
      }

      final files = recordingsDir.listSync().whereType<File>().toList();
      files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      debugPrint('Error getting recorded files: $e');
      return [];
    }
  }

  /// Delete a recording file
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Recording deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      return false;
    }
  }

  /// Get total size of all recordings
  Future<int> getTotalRecordingsSize() async {
    try {
      final files = await getRecordedFiles();
      int totalSize = 0;
      for (final file in files) {
        totalSize += await file.length();
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating recordings size: $e');
      return 0;
    }
  }

  /// Dispose of the audio recorder
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      await _audioRecorder.dispose();
    } catch (e) {
      debugPrint('Error disposing audio recorder: $e');
    }
  }
}
