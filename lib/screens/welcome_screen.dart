import 'package:flutter/material.dart';
import 'package:meeting_gist/screens/recording_screen.dart';
import 'package:meeting_gist/screens/live_transcription_screen.dart';

class WelcomeScreen extends StatefulWidget{
  @override
  State<WelcomeScreen> createState() {

    return _WelcomeScreenState();
  }
}

class _WelcomeScreenState extends State<WelcomeScreen>{

  TextEditingController _textEditingController = new TextEditingController();

  Widget build(context){
    return  
    Center(
    child: 
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ElevatedButton(
              // onPressed: (){
              //   Navigator.of(context).push(
              //     MaterialPageRoute(
              //       builder: (context) => RecordingScreen()
              //       ),
              //       );

              // }, 
              // child: Text("Using Record and Google Speech")
              // ),

              SizedBox(height: 40,),
            ElevatedButton(
              onPressed: (){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Total Duration Of Meeting (In Minutes)'),
          content: TextField(
            controller: _textEditingController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Input the total no of minutes",
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        RecorderPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  },
  child: const Text("Using Speech to Text"),



              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SpeechSampleApp(),
                    ),
                  );
                },
                child: const Text("Live Transcription with Speaker Diarization"),
              ),
          ],
        ),
    );
  }
}