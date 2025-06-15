import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:meeting_gist/widgets/recording_button.dart';
import 'package:meeting_gist/widgets/recording_widget.dart';
import 'package:meeting_gist/screens/show_text.dart';
import 'package:meeting_gist/widgets/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

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


   @override
  void initState() {
    _audioRecorder = AudioRecorder();
    super.initState();
  }

  void dispose() {
    _audioRecorder.dispose();
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
    isLoading=true;
    });
    try{
    if (audioPath == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.100.102:5000/diarize'),
    );

    request.files.add(await http.MultipartFile.fromPath('audio', audioPath!));
    var response = await request.send();
    if(response.statusCode==200)
    {
    var respStr = await response.stream.bytesToString();
    final decoded = jsonDecode(respStr);
    if (decoded is List) {
      setState(() {
        responseSegments = List<Map<String, dynamic>>.from(decoded);
      });
    
    print("Server Response: $respStr");
                    Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ShowText(responseSegments),
                  ),
                );
    }
    else{
    AppSnackBar.error(context, "error : ${response.statusCode}");

    }
    }
    }
    catch(e)
    {
      print("ERROR IN Recording: $e");
    Navigator.pop(context);

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body:  isLoading?
          const Center(
            child: CircularProgressIndicator(),
          ):
          Container(
            height: screenHeight,
            width: screenWidth,
            child: 
          Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (isRecording) const RecordingWidget(),
          const SizedBox(height: 16),
          RecordingButton(
            isRecording: isRecording,
            onPressed: () => _record(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _stopRecording, child: Text('Meeting Completed')),

        ],
      ),
          ),
    );
  }
}
