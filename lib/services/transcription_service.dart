import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meeting_gist/models/transcription_result.dart';
import 'package:meeting_gist/services/onnx_service.dart';

/// Service for coordinating transcription and diarization
class TranscriptionService {
  final OnnxService onnxService;

  TranscriptionService({required this.onnxService});

  /// Process audio file with progress callback
  Future<TranscriptionResult?> processAudioFile(
    String audioPath, {
    required Function(double) onProgress,
  }) async {
    try {
      final startTime = DateTime.now();
      onProgress(0.0);

      // Start listening to native progress updates
      onnxService.listenToProgress(onProgress);

      // Process audio
      final result = await onnxService.processAudio(audioPath);
      onProgress(1.0);

      if (result == null) {
        debugPrint('Processing returned null');
        return null;
      }

      // Parse results
      final segments = _parseSegments(result);

      final processingTime = DateTime.now().difference(startTime);

      return TranscriptionResult(
        segments: segments,
        audioPath: audioPath,
        processingTime: processingTime,
        modelVersion: result['model_version'] ?? '1.0',
      );
    } catch (e) {
      debugPrint('Error processing audio file: $e');
      return null;
    } finally {
      onnxService.stopListeningToProgress();
    }
  }

  /// Parse segments from native response
  List<TranscriptionSegment> _parseSegments(Map<String, dynamic> result) {
    try {
      final segmentsList = result['segments'] as List?;

      if (segmentsList == null || segmentsList.isEmpty) {
        return [];
      }

      return segmentsList.asMap().entries.map((entry) {
        final index = entry.key;
        final segment = entry.value as Map<dynamic, dynamic>;

        return TranscriptionSegment(
          id: index,
          startTime: _toDouble(segment['start_time']),
          endTime: _toDouble(segment['end_time']),
          text: segment['text']?.toString() ?? '',
          speaker: segment['speaker']?.toString() ?? 'Unknown',
          confidence: _toDouble(segment['confidence']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing segments: $e');
      return [];
    }
  }

  /// Safe conversion to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get speaker statistics
  Map<String, dynamic> getSpeakerStats(TranscriptionResult result) {
    try {
      final groupedBySpeaker = result.groupedBySpeaker;
      final stats = <String, dynamic>{};

      for (final entry in groupedBySpeaker.entries) {
        final speaker = entry.key;
        final segments = entry.value;

        final totalDuration =
            segments.fold<double>(0, (sum, seg) => sum + (seg.endTime - seg.startTime));
        final wordCount = segments
            .fold<int>(0, (sum, seg) => sum + seg.text.split(' ').length);
        final avgConfidence = segments.fold<double>(0, (sum, seg) => sum + seg.confidence) /
            (segments.isNotEmpty ? segments.length : 1);

        stats[speaker] = {
          'segment_count': segments.length,
          'total_duration_seconds': totalDuration,
          'word_count': wordCount,
          'average_confidence': avgConfidence,
        };
      }

      return stats;
    } catch (e) {
      debugPrint('Error calculating speaker stats: $e');
      return {};
    }
  }

  /// Export results to JSON
  String exportToJson(TranscriptionResult result) {
    try {
      return _jsonEncode(result.toJson());
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
      return '{}';
    }
  }

  /// Simple JSON encoding
  String _jsonEncode(Map<String, dynamic> data) {
    final buffer = StringBuffer('{');
    final entries = data.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":');

      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else if (entry.value is num) {
        buffer.write(entry.value);
      } else if (entry.value is List) {
        buffer.write('[');
        final list = entry.value as List;
        for (int j = 0; j < list.length; j++) {
          if (list[j] is Map) {
            buffer.write(_jsonEncode(list[j] as Map<String, dynamic>));
          } else if (list[j] is String) {
            buffer.write('"${list[j]}"');
          } else {
            buffer.write(list[j]);
          }
          if (j < list.length - 1) buffer.write(',');
        }
        buffer.write(']');
      } else if (entry.value is Map) {
        buffer.write(_jsonEncode(entry.value as Map<String, dynamic>));
      } else {
        buffer.write(entry.value);
      }

      if (i < entries.length - 1) buffer.write(',');
    }

    buffer.write('}');
    return buffer.toString();
  }
}
