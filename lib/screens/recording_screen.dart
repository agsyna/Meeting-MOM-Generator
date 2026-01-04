import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:meeting_gist/widgets/custom_circular_progress_indicator.dart';
import 'package:meeting_gist/widgets/recording_widget.dart';
import 'package:meeting_gist/screens/show_text.dart';
import 'package:meeting_gist/widgets/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/rendering.dart';

class RecorderPage extends StatefulWidget {
  @override
  _RecorderPageState createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
    bool isRecording = false;
  late final AudioRecorder _audioRecorder;
  String? audioPath;
  bool isLoading = false;
    List<Map<String, dynamic>> responseSegments = [];

  double _progress = 0.0;
  late final Ticker _ticker;

  static const int _maxLoadingSeconds = 30;

   @override
  void initState() {
    _audioRecorder = AudioRecorder();
    super.initState();
    _ticker = Ticker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (!isLoading) return;
    final seconds = elapsed.inMilliseconds / 1000.0;
    setState(() {
      _progress = (seconds / _maxLoadingSeconds).clamp(0.0, 1.0);
    });
  }

  void dispose() {
    _audioRecorder.dispose();
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try{
    final dir = await getApplicationDocumentsDirectory();
    audioPath = '${dir.path}/audio.wav';

    await _audioRecorder.start(
      path: audioPath!,
      RecordConfig(
      encoder: AudioEncoder.wav,
      bitRate: 128000,
      sampleRate: 16000,
      ),
    );

    setState(() {});
    }
    catch(e)
    {
      AppSnackBar.error(context, "e");
      print("ERROR WHILE RECORDING : $e");
    }
  }

  Future<void> _stopRecording() async {
    try{
    String? path = await _audioRecorder.stop();
      setState(() {
      isRecording=false;
        audioPath = path!;
      });
      _sendToServer();
      debugPrint('=========>>>>>> PATH: $audioPath <<<<<<===========');
    } catch (e) {
      AppSnackBar.error(context, "e");
      debugPrint('ERROR WHILE STOP RECORDING: $e');
    }
  }

  Future<void> _sendToServer() async {
    setState(() {
      isLoading = true;
      _progress = 0.0;
    });
    _ticker.start();
    try {
      if (audioPath == null) return;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.5.13.151:5000/diarize'),
      );
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath!));
      var response = await request.send();
      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        final decoded = jsonDecode(respStr);
        if (decoded is List) {
          setState(() {
            responseSegments = List<Map<String, dynamic>>.from(decoded);
          });
          _ticker.stop();
          setState(() {
            isLoading = false;
            _progress = 0.0;
          });
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShowText(responseSegments),
            ),
          );
        } else {
          AppSnackBar.error(context, "error : ${response.statusCode}");
        }
      }
    } catch (e) {
      print("ERROR IN Recording: $e");
      Navigator.pop(context);
    } finally {
      setState(() {
        isLoading = false;
        _progress = 0.0;
      });
      _ticker.stop();
    }
  }

  void _record() async {
    if (isRecording == false) {
      final status = await Permission.microphone.request();

      if (status == PermissionStatus.granted) {
        setState(() {
          isRecording = true;
        });
        await _startRecording();
      } else if (status == PermissionStatus.permanentlyDenied) {
        debugPrint('Permission permanently denied');
      }
    } else {
      await _stopRecording();

      setState(() {
        isRecording = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final showPleaseWait = isLoading && (_progress >= 1.0);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Recording',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? _buildLoadingUI(showPleaseWait)
          : _buildRecordingUI(),
    );
  }

  Widget _buildLoadingUI(bool showPleaseWait) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomCircularProgressIndicator(progress: _progress.clamp(0.0, 1.0)),
          if (showPleaseWait) ...[
            const SizedBox(height: 32),
            const Text(
              'Processing your meeting',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait...',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 60),
              
              // Large Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF7785FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  size: 60,
                  color: Color(0xFF7785FF),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status Text
              Text(
                isRecording ? 'Recording in progress' : 'Ready to record',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                isRecording 
                  ? 'Your meeting is being recorded'
                  : 'Start recording your meeting',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Recording Widget
              if (isRecording) ...[
                const RecordingWidget(),
                const SizedBox(height: 40),
              ],
              
              // Buttons
              Column(
                children: [
                  // Primary Button - Record/Stop
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: () => _record(),
                      style: FilledButton.styleFrom(
                        backgroundColor: isRecording 
                          ? Colors.red 
                          : const Color(0xFF7785FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isRecording ? 'Stop Recording' : 'Start Recording',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Secondary Button - Complete
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _stopRecording,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF7785FF),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Meeting Completed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7785FF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),           
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
