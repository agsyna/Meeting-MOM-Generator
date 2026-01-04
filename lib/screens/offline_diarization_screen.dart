import 'package:flutter/material.dart';
import 'package:meeting_gist/models/transcription_result.dart';
import 'package:meeting_gist/services/audio_service.dart';
import 'package:meeting_gist/services/diarization_transcription_service.dart';
import 'package:meeting_gist/widgets/custom_circular_progress_indicator.dart';

/// Screen for offline diarization + transcription feature
class OfflineDiarizationScreen extends StatefulWidget {
  const OfflineDiarizationScreen({Key? key}) : super(key: key);

  @override
  State<OfflineDiarizationScreen> createState() =>
      _OfflineDiarizationScreenState();
}

class _OfflineDiarizationScreenState extends State<OfflineDiarizationScreen> {
  late DiarizationTranscriptionService _service;
  late AudioService _audioService;

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isInitializing = true;
  double _processingProgress = 0.0;
  String _statusMessage = '';
  TranscriptionResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isInitializing = true;
        _statusMessage = 'Initializing models...';
        _errorMessage = null;
      });

      _audioService = AudioService();
      _service = DiarizationTranscriptionService(audioService: _audioService);

      // Initialize both Whisper and diarization models
      final initialized = await _service.initialize(
        // whisperModel: 'tiny',
        language: 'en',
      );

      if (initialized) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Ready to record';
        });
      } else {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to initialize models';
          _statusMessage = 'Error: Failed to initialize models';
        });
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Initialization error: $e';
        _statusMessage = 'Error initializing services';
      });
      debugPrint('Error initializing services: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_isInitializing) {
      _showSnackBar('Please wait for models to initialize', 'error');
      return;
    }

    try {
      final success = await _audioService.startRecording();

      if (success) {
        setState(() {
          _isRecording = true;
          _statusMessage = 'Recording...';
          _errorMessage = null;
        });
        _showSnackBar('Recording started', 'success');
      } else {
        _showSnackBar('Failed to start recording', 'error');
      }
    } catch (e) {
      _showSnackBar('Error starting recording: $e', 'error');
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final audioPath = await _service.stopRecording();

      setState(() {
        _isRecording = false;
        _statusMessage = 'Processing audio...';
        _isProcessing = true;
        _processingProgress = 0.0;
        _errorMessage = null;
      });

      if (audioPath != null) {
        await _processAudio(audioPath);
      } else {
        _showSnackBar('Failed to save recording', 'error');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showSnackBar('Error stopping recording: $e', 'error');
      setState(() => _isProcessing = false);
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _processAudio(String audioPath) async {
    try {
      final result = await _service.processRecordedAudio(
        audioPath: audioPath,
        onProgress: (progress) {
          setState(() {
            _processingProgress = progress;
          });
        },
        onStatusUpdate: (status) {
          setState(() {
            _statusMessage = status;
          });
        },
      );

      if (result != null) {
        setState(() {
          _result = result;
          _isProcessing = false;
          _processingProgress = 1.0;
          _statusMessage = 'Processing complete!';
          _errorMessage = null;
        });
        _showSnackBar(
            'Processing complete! ${result.segments.length} segments found',
            'success');
      } else {
        _showSnackBar('Failed to process audio', 'error');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showSnackBar('Error processing audio: $e', 'error');
      setState(() => _isProcessing = false);
      debugPrint('Error processing audio: $e');
    }
  }

  void _reset() {
    setState(() {
      _isRecording = false;
      _isProcessing = false;
      _processingProgress = 0.0;
      _result = null;
      _statusMessage = 'Ready to record';
      _errorMessage = null;
    });
  }

  void _cancelRecording() async {
    await _service.cancelRecording();
    setState(() {
      _isRecording = false;
      _statusMessage = 'Recording cancelled';
    });
    _showSnackBar('Recording cancelled', 'info');
  }

  void _showSnackBar(String message, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: type == 'success'
            ? Colors.green
            : type == 'error'
                ? Colors.red
                : Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Diarization & Transcription'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isInitializing
          ? _buildInitializingState()
          : _isRecording
              ? _buildRecordingState()
              : _isProcessing
                  ? _buildProcessingState()
                  : _result != null
                      ? _buildResultsState()
                      : _buildIdleState(),
    );
  }

  /// Initializing state
  Widget _buildInitializingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667eea),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Recording state
  Widget _buildRecordingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Wave animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                Icons.mic,
                size: 60,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Recording...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 48),
          // Stop button
          ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Recording'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Cancel button
          OutlinedButton.icon(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Processing state
  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomCircularProgressIndicator(
            progress: _processingProgress,
          ),
          const SizedBox(height: 32),
          Text(
            '${(_processingProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Idle state (ready to record)
  Widget _buildIdleState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.settings_voice_rounded,
                        size: 48,
                        color: Color(0xFF667eea),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Offline Diarization',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Features
                _buildFeatureItem(
                  icon: Icons.mic,
                  title: 'Record Audio',
                  description: 'Record audio from your microphone',
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  icon: Icons.people,
                  title: 'Speaker Diarization',
                  description: 'Identify and separate speakers',
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  icon: Icons.subtitles,
                  title: 'Transcription',
                  description: 'Transcribe each speaker segment',
                ),
                const SizedBox(height: 40),
                // Record button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FloatingActionButton.extended(
                    onPressed: _startRecording,
                    label: const Text('Start Recording'),
                    icon: const Icon(Icons.mic),
                    backgroundColor: const Color(0xFF667eea),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Results state
  Widget _buildResultsState() {
    if (_result == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF667eea).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    '${_result!.segments.length}',
                    'Segments',
                  ),
                  _buildSummaryItem(
                    '${_result!.speakers.length}',
                    'Speakers',
                  ),
                  _buildSummaryItem(
                    '${_result!.processingTime.inSeconds}s',
                    'Time',
                  ),
                ],
              ),
            ],
          ),
        ),
        // Segments list
        Expanded(
          child: _buildSegmentsList(),
        ),
        // Reset button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Record Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build segments list
  Widget _buildSegmentsList() {
    if (_result?.segments.isEmpty ?? true) {
      return const Center(
        child: Text('No segments found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _result!.segments.length,
      itemBuilder: (context, index) {
        final segment = _result!.segments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: _getSpeakerColor(segment.speaker),
              child: Text(
                segment.speaker.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              segment.speaker,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  segment.text,
                  // maxLines: 2,
                  // overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  segment.formattedTimestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Feature item widget
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF667eea), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Summary item widget
  Widget _buildSummaryItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF667eea),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Get speaker color based on speaker name
  Color _getSpeakerColor(String speaker) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
    ];
    return colors[speaker.hashCode % colors.length];
  }
}
