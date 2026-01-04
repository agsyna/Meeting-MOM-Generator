import 'package:flutter/material.dart';
import 'package:meeting_gist/services/audio_service.dart';
import 'package:meeting_gist/services/onnx_service.dart';
import 'package:meeting_gist/services/transcription_service.dart';
import 'package:meeting_gist/models/transcription_result.dart';
import 'package:meeting_gist/widgets/custom_circular_progress_indicator.dart';
import 'package:meeting_gist/widgets/recording_widget.dart';

/// Main recording and processing screen
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late AudioService _audioService;
  late OnnxService _onnxService;
  late TranscriptionService _transcriptionService;

  bool _isRecording = false;
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  TranscriptionResult? _result;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _audioService = AudioService();
      _onnxService = OnnxService();
      _transcriptionService = TranscriptionService(onnxService: _onnxService);

      // Initialize ONNX models
      final whisperPath = '/path/to/whisper-model.onnx';
      final diarizationPath = '/path/to/diarization-model.onnx';

      final initialized = await _onnxService.initialize(
        whisperModelPath: whisperPath,
        diarizationModelPath: diarizationPath,
      );

      if (!initialized) {
        _showSnackBar('Failed to initialize ONNX models', 'error');
      }
    } catch (e) {
      _showSnackBar('Error initializing services: $e', 'error');
    }
  }

  Future<void> _startRecording() async {
    try {
      final success = await _audioService.startRecording();
      if (success) {
        setState(() {
          _isRecording = true;
          _statusMessage = 'Recording...';
        });
        _showSnackBar('Recording started', 'success');
      } else {
        _showSnackBar('Failed to start recording', 'error');
      }
    } catch (e) {
      _showSnackBar('Error starting recording: $e', 'error');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final audioPath = await _audioService.stopRecording();
      
      setState(() {
        _isRecording = false;
        _statusMessage = 'Processing audio...';
        _isProcessing = true;
        _processingProgress = 0.0;
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
    }
  }

  Future<void> _processAudio(String audioPath) async {
    try {
      setState(() => _statusMessage = 'Transcribing audio...');

      final result = await _transcriptionService.processAudioFile(
        audioPath,
        onProgress: (progress) {
          setState(() {
            _processingProgress = progress;
            if (progress < 0.5) {
              _statusMessage = 'Transcribing... ${(progress * 2 * 100).toStringAsFixed(0)}%';
            } else {
              _statusMessage = 'Speaker diarization... ${((progress - 0.5) * 2 * 100).toStringAsFixed(0)}%';
            }
          });
        },
      );

      if (result != null) {
        setState(() {
          _result = result;
          _isProcessing = false;
          _processingProgress = 1.0;
          _statusMessage = 'Processing complete!';
        });
        _showSnackBar('Processing complete! ${result.segments.length} segments found',
            'success');
      } else {
        _showSnackBar('Failed to process audio', 'error');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _showSnackBar('Error processing audio: $e', 'error');
      setState(() => _isProcessing = false);
    }
  }

  void _reset() {
    setState(() {
      _isRecording = false;
      _isProcessing = false;
      _processingProgress = 0.0;
      _result = null;
      _statusMessage = '';
    });
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    _onnxService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null && !_isProcessing) {
      return _buildResultsScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Transcription'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing) ...[
                  CustomCircularProgressIndicator(
                    progress: _processingProgress,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ] else if (_isRecording) ...[
                  RecordingWidget(),
                  const SizedBox(height: 24),
                  Text(
                    'Recording...',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ] else ...[
                  Icon(
                    Icons.mic_none,
                    size: 80,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tap the mic button to start recording',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_isRecording)
                  ElevatedButton.icon(
                    onPressed: _audioService.cancelRecording,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                FloatingActionButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  backgroundColor: _isRecording ? Colors.red : Theme.of(context).primaryColor,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    if (_result == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcription Results'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Segments (${_result!.segments.length})'),
                Tab(text: 'Summary'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSegmentsTab(),
                  _buildSummaryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _result!.segments.length,
      itemBuilder: (context, index) {
        final segment = _result!.segments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(segment.text),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Speaker: ${segment.speaker}'),
                Text(segment.formattedTimestamp),
              ],
            ),
            trailing: Text('${(segment.confidence * 100).toStringAsFixed(0)}%'),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    final speakers = _result!.speakers;
    final totalDuration =
        _result!.segments.isNotEmpty ? _result!.segments.last.endTime : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Total Duration:', _formatDuration(totalDuration)),
                  _buildSummaryRow('Total Segments:', '${_result!.segments.length}'),
                  _buildSummaryRow('Unique Speakers:', '${speakers.length}'),
                  _buildSummaryRow('Processing Time:', '${_result!.processingTime.inSeconds}s'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Speakers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ..._buildSpeakerCards(speakers),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpeakerCards(List<String> speakers) {
    return speakers.map((speaker) {
      final segments = _result!.segments.where((s) => s.speaker == speaker).toList();
      final duration = segments.fold<double>(0, (sum, s) => sum + (s.endTime - s.startTime));
      final wordCount = segments.fold<int>(0, (sum, s) => sum + s.text.split(' ').length);

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text('${segments.length} segments • ${_formatDuration(duration)}'),
                    Text('$wordCount words'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _formatDuration(double seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }
}
