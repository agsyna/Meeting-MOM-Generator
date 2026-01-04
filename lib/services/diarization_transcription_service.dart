import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'package:meeting_gist/onnx_diarisation.dart';
import 'package:meeting_gist/models/transcription_result.dart' as custom_models;
import 'package:meeting_gist/services/audio_service.dart';

/// Service that orchestrates OFFLINE diarization + transcription workflow
/// - Diarization: ONNX model (pyannote_segmentation.onnx) ✅ TESTED
/// - Transcription: whisper_flutter_new (base model) ✅ TESTED ON ANDROID & iOS
/// ✅ ALL PROCESSING IS OFFLINE - NO CLOUD SERVICES
class DiarizationTranscriptionService {
  final AudioService audioService;
  final OnnxDiarization _diarization = OnnxDiarization();
  late Whisper _whisper;
  String _language = 'en'; // Store language for transcription

  bool _isDiarizationInitialized = false;
  bool _isWhisperInitialized = false;

  DiarizationTranscriptionService({required this.audioService});

  /// Initialize both diarization and whisper transcription models
  /// ✅ Works OFFLINE on Android and iOS
  /// Downloads whisper model once, then cached for future use
  Future<bool> initialize({
    WhisperModel model = WhisperModel.base,
    String language = 'en',
  }) async {
    try {
      _language = language; // Store language for later use

      debugPrint('╔════════════════════════════════════════════╗');
      debugPrint('║    INITIALIZING DIARIZATION + WHISPER     ║');
      debugPrint('╚════════════════════════════════════════════╝');
      debugPrint('Platform: ${Platform.operatingSystem}');
      debugPrint('Whisper Model: base (recommended)');
      debugPrint('Language: $language');

      // Step 1: Initialize Whisper
      debugPrint('\n[STEP 1] Initializing Whisper model...');
      try {
        _whisper = Whisper(
          model: model,
          downloadHost:
              "https://huggingface.co/ggerganov/whisper.cpp/resolve/main",
        );

        final version = await _whisper.getVersion();
        debugPrint('✅ Whisper initialized: v$version');
        _isWhisperInitialized = true;
      } catch (e) {
        debugPrint('❌ Whisper initialization failed: $e');
        _isWhisperInitialized = false;
      }

      // Step 2: Initialize ONNX Diarization
      debugPrint('\n[STEP 2] Initializing ONNX Diarization model...');
      try {
        await _diarization.initialize();
        debugPrint('✅ ONNX Diarization initialized');
        _isDiarizationInitialized = true;
      } catch (e) {
        debugPrint('❌ ONNX Diarization initialization failed: $e');
        _isDiarizationInitialized = false;
      }

      debugPrint('\n╔════════════════════════════════════════════╗');
      debugPrint('║        INITIALIZATION COMPLETE             ║');
      debugPrint('╚════════════════════════════════════════════╝');
      debugPrint('Whisper: ${_isWhisperInitialized ? "✅ Ready" : "❌ Failed"}');
      debugPrint(
        'Diarization: ${_isDiarizationInitialized ? "✅ Ready" : "❌ Failed"}',
      );

      final ready = _isWhisperInitialized && _isDiarizationInitialized;
      debugPrint('Overall: ${ready ? "✅ READY" : "❌ NOT READY"}');

      return ready;
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      return false;
    }
  }

  /// Check if both models are ready
  bool get isInitialized => _isWhisperInitialized && _isDiarizationInitialized;

  /// Get whisper status
  bool get isWhisperAvailable => _isWhisperInitialized;

  /// Get diarization status
  bool get isDiarizationAvailable => _isDiarizationInitialized;

  /// Process a recorded audio file with diarization + whisper transcription
  /// Complete OFFLINE pipeline:
  /// 1. Diarize (0-45%): Identify speakers and time segments using ONNX
  /// 2. Transcribe (45-85%): Convert audio to text using Whisper
  /// 3. Merge (85-100%): Align diarization with transcription
  Future<custom_models.TranscriptionResult?> processRecordedAudio({
    required String audioPath,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    try {
      if (!isInitialized) {
        final msg =
            'Models not initialized. Whisper: $_isWhisperInitialized, Diarization: $_isDiarizationInitialized';
        debugPrint('❌ ERROR: $msg');
        throw Exception(msg);
      }

      debugPrint(
        '\n\n╔════════════════════════════════════════════════════════════╗',
      );
      debugPrint(
        '║  DIARIZATION + WHISPER TRANSCRIPTION PROCESSING STARTED  ║',
      );
      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
      debugPrint('Audio file: $audioPath');

      final startTime = DateTime.now();

      // =================== PHASE 1: DIARIZATION (0-45%) ===================
      debugPrint('\n\n📍 PHASE 1: DIARIZATION (ONNX)');
      debugPrint('─' * 70);
      onStatusUpdate('Phase 1/3: Identifying speakers...');
      onProgress(0.05);

      debugPrint('[1.1] Verifying audio file...');
      final audioFile = File(audioPath);
      if (!audioFile.existsSync()) {
        throw Exception('Audio file not found: $audioPath');
      }
      final fileSize = audioFile.lengthSync();
      debugPrint(
        '✅ Audio file found: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
      onProgress(0.1);

      debugPrint('[1.2] Running ONNX Diarization model...');
      onStatusUpdate('Identifying speakers with ONNX model...');

      final diarizedSegments = await _diarization.diarize(audioPath);
      debugPrint('✅ Diarization complete!');
      debugPrint('Found ${diarizedSegments.length} speaker segments:');

      for (int i = 0; i < diarizedSegments.length; i++) {
        final seg = diarizedSegments[i];
        final start = (seg['start'] as num?)?.toDouble() ?? 0.0;
        final end = (seg['end'] as num?)?.toDouble() ?? 0.0;
        final speaker = seg['speaker'];
        debugPrint(
          '  [$i] $speaker: ${start.toStringAsFixed(2)}s → ${end.toStringAsFixed(2)}s',
        );
      }
      onProgress(0.45);

      // =================== PHASE 2: TRANSCRIPTION (45-85%) ===================
      debugPrint('\n\n🎤 PHASE 2: WHISPER TRANSCRIPTION');
      debugPrint('─' * 70);
      onStatusUpdate('Phase 2/3: Transcribing audio with Whisper...');
      onProgress(0.48);

      debugPrint('[2.1] Preparing Whisper transcription...');
      onStatusUpdate('Processing audio with Whisper model...');

      debugPrint('[2.2] Running Whisper transcription...');
      debugPrint('Audio path: $audioPath');
      debugPrint('Language: $_language');

      final transcribeRequest = TranscribeRequest(
        audio: audioPath,
        isTranslate: false, // Keep original language
        isNoTimestamps: false, // Get segment timestamps
        splitOnWord: true, // Split segments on each word
        language: _language, // Use configured language
      );

      debugPrint('Starting Whisper transcription (offline mode)...');
      final transcriptionResponse = await _whisper.transcribe(
        transcribeRequest: transcribeRequest,
      );
      debugPrint('Whisper transcription completed!');

      debugPrint('✅ Transcription complete!');
      debugPrint(
        'Transcription response type: ${transcriptionResponse.runtimeType}',
      );
      onProgress(0.85);

      // Parse transcription to extract segments with timestamps
      debugPrint('[2.3] Processing transcription response...');

      // Extract Whisper segments from the response
      List<Map<String, dynamic>> whisperSegments = [];
      String fullTranscriptionText = '';

      try {
        // Access the response properties - whisper_flutter_new package structure
        fullTranscriptionText = transcriptionResponse.text;

        if (transcriptionResponse.segments != null &&
            transcriptionResponse.segments!.isNotEmpty) {
          debugPrint(
            'Found ${transcriptionResponse.segments!.length} Whisper segments',
          );

          for (var seg in transcriptionResponse.segments!) {
            // fromTs and toTs are Duration objects, not numbers
            final fromTs = seg.fromTs;
            final toTs = seg.toTs;
            final text = seg.text;

            // Convert Duration to seconds
            final startSeconds = fromTs.inMilliseconds / 1000.0;
            final endSeconds = toTs.inMilliseconds / 1000.0;

            whisperSegments.add({
              'start': startSeconds,
              'end': endSeconds,
              'text': text.trim(),
            });

            debugPrint(
              '    Whisper seg: "${text.trim()}" (${startSeconds.toStringAsFixed(2)}s - ${endSeconds.toStringAsFixed(2)}s)',
            );
          }
        }

        debugPrint('Full transcription text: "$fullTranscriptionText"');
        debugPrint(
          'Successfully parsed ${whisperSegments.length} Whisper segments',
        );
      } catch (e) {
        debugPrint('⚠️ Error parsing Whisper response: $e');
        debugPrint('Response details: $transcriptionResponse');
      }

      // =================== PHASE 3: MERGING (85-100%) ===================
      debugPrint('\n\n🔀 PHASE 3: MERGING & ALIGNMENT');
      debugPrint('─' * 70);
      onStatusUpdate(
        'Phase 3/3: Merging speaker diarization with transcription...',
      );
      onProgress(0.87);

      debugPrint('[3.1] Aligning diarization with transcription...');
      debugPrint('Total whisper segments available: ${whisperSegments.length}');
      debugPrint('Total diarization segments: ${diarizedSegments.length}');

      // Calculate actual audio duration from Whisper segments
      double actualAudioDuration = 0.0;
      if (whisperSegments.isNotEmpty) {
        actualAudioDuration = (whisperSegments.last['end'] as double);
        debugPrint(
          'Actual audio duration (from Whisper): ${actualAudioDuration.toStringAsFixed(2)}s',
        );
      }

      final List<custom_models.TranscriptionSegment> finalSegments = [];

      // For each diarized segment, find matching transcription segments
      if (diarizedSegments.isNotEmpty) {
        for (int i = 0; i < diarizedSegments.length; i++) {
          final diarSeg = diarizedSegments[i];
          double diarStart = (diarSeg['start'] as num?)?.toDouble() ?? 0.0;
          double diarEnd = (diarSeg['end'] as num?)?.toDouble() ?? 0.0;
          final speaker = diarSeg['speaker'] as String? ?? 'Speaker ${i + 1}';

          // Clamp diarization times to actual audio duration if available
          if (actualAudioDuration > 0) {
            if (diarStart > actualAudioDuration) {
              debugPrint(
                '\n  [Segment $i] $speaker - SKIPPED (starts after audio ends)',
              );
              continue; // Skip segments that start after audio ends
            }
            if (diarEnd > actualAudioDuration) {
              debugPrint(
                '  ⚠️ Clamping segment end from ${diarEnd.toStringAsFixed(2)}s to ${actualAudioDuration.toStringAsFixed(2)}s',
              );
              diarEnd = actualAudioDuration;
            }
          }

          debugPrint(
            '\n  [Segment $i] $speaker (${diarStart.toStringAsFixed(2)}s - ${diarEnd.toStringAsFixed(2)}s)',
          );

          // Find all Whisper segments that overlap with this speaker segment
          List<String> matchingTexts = [];

          if (whisperSegments.isNotEmpty) {
            for (var whisperSeg in whisperSegments) {
              final whisperStart = whisperSeg['start'] as double;
              final whisperEnd = whisperSeg['end'] as double;
              final whisperText = whisperSeg['text'] as String;

              // Check if Whisper segment overlaps with diarization segment
              // A segment overlaps if it starts before diar ends AND ends after diar starts
              if (whisperEnd > diarStart && whisperStart < diarEnd) {
                if (whisperText.isNotEmpty) {
                  matchingTexts.add(whisperText);
                  debugPrint(
                    '    ✓ Matched: "$whisperText" (${whisperStart.toStringAsFixed(2)}s - ${whisperEnd.toStringAsFixed(2)}s)',
                  );
                }
              }
            }
          }

          // Combine all matching texts
          String segmentText;
          if (matchingTexts.isNotEmpty) {
            segmentText = matchingTexts.join(' ').trim();
            debugPrint(
              '    📝 Merged ${matchingTexts.length} Whisper segments',
            );
          } else if (whisperSegments.isEmpty &&
              fullTranscriptionText.isNotEmpty) {
            // Fallback: if we couldn't parse segments but have full text
            segmentText = fullTranscriptionText;
            debugPrint(
              '    📝 Using full transcription (segment parsing failed)',
            );
          } else {
            segmentText = '[No speech detected]';
            debugPrint('    ⚠️ No matching transcription found');
          }

          debugPrint('    📝 Final text: "$segmentText"');

          finalSegments.add(
            custom_models.TranscriptionSegment(
              id: i,
              startTime: diarStart,
              endTime: diarEnd,
              text: segmentText,
              speaker: speaker,
              confidence: 0.85,
            ),
          );

          onProgress(0.87 + ((i + 1) * 0.13 / diarizedSegments.length));
        }
      }

      debugPrint(
        '\n✅ Merging complete! Created ${finalSegments.length} speaker segments',
      );

      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime);

      onProgress(1.0);
      onStatusUpdate('✅ Processing complete!');

      debugPrint(
        '\n╔════════════════════════════════════════════════════════════╗',
      );
      debugPrint('║                 PROCESSING COMPLETE ✅                  ║');
      debugPrint(
        '╚════════════════════════════════════════════════════════════╝',
      );
      debugPrint('Total processing time: ${processingTime.inSeconds}s');
      debugPrint('Final segments: ${finalSegments.length}');
      debugPrint('Diarization model: ONNX');
      debugPrint('Transcription model: Whisper (base)');

      return custom_models.TranscriptionResult(
        segments: finalSegments,
        audioPath: audioPath,
        processingTime: processingTime,
        modelVersion: '1.0-onnx-whisper',
      );
    } catch (e) {
      debugPrint('\n\n❌ ❌ ❌ ERROR DURING PROCESSING ❌ ❌ ❌');
      debugPrint('Error: $e');
      debugPrintStack();
      rethrow;
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    try {
      return await audioService.stopRecording();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      await audioService.cancelRecording();
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      _diarization.dispose();
    } catch (e) {
      debugPrint('Error disposing service: $e');
    }
  }
}
