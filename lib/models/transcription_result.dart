/// Model representing a transcription segment with speaker diarization
class TranscriptionSegment {
  final int id;
  final double startTime;
  final double endTime;
  final String text;
  final String speaker;
  final double confidence;

  TranscriptionSegment({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.text,
    required this.speaker,
    this.confidence = 0.0,
  });

  /// Get formatted timestamp (HH:MM:SS format)
  String get formattedStartTime => _formatSeconds(startTime);
  String get formattedEndTime => _formatSeconds(endTime);
  String get formattedTimestamp =>
      '${formattedStartTime} - ${formattedEndTime}';

  static String _formatSeconds(double seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toStringAsFixed(2).padLeft(5, '0');
    return '$hours:$minutes:$secs';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'start_time': startTime,
        'end_time': endTime,
        'text': text,
        'speaker': speaker,
        'confidence': confidence,
      };

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) {
    return TranscriptionSegment(
      id: json['id'] ?? 0,
      startTime: (json['start_time'] ?? 0).toDouble(),
      endTime: (json['end_time'] ?? 0).toDouble(),
      text: json['text'] ?? '',
      speaker: json['speaker'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

/// Container for complete transcription results
class TranscriptionResult {
  final List<TranscriptionSegment> segments;
  final String audioPath;
  final Duration processingTime;
  final String modelVersion;

  TranscriptionResult({
    required this.segments,
    required this.audioPath,
    required this.processingTime,
    this.modelVersion = '1.0',
  });

  /// Combine all text from segments
  String get fullText => segments.map((s) => s.text).join(' ');

  /// Group segments by speaker
  Map<String, List<TranscriptionSegment>> get groupedBySpeaker {
    final groups = <String, List<TranscriptionSegment>>{};
    for (final segment in segments) {
      groups.putIfAbsent(segment.speaker, () => []).add(segment);
    }
    return groups;
  }

  /// Get speaker list
  List<String> get speakers =>
      segments.map((s) => s.speaker).toSet().toList()..sort();

  Map<String, dynamic> toJson() => {
        'segments': segments.map((s) => s.toJson()).toList(),
        'audio_path': audioPath,
        'processing_time_ms': processingTime.inMilliseconds,
        'model_version': modelVersion,
      };

  factory TranscriptionResult.fromJson(
    Map<String, dynamic> json,
    String audioPath,
  ) {
    return TranscriptionResult(
      segments: (json['segments'] as List)
          .map((s) => TranscriptionSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      audioPath: audioPath,
      processingTime:
          Duration(milliseconds: json['processing_time_ms'] ?? 0),
      modelVersion: json['model_version'] ?? '1.0',
    );
  }
}
