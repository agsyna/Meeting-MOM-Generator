import 'package:flutter/material.dart';

class RecordingButton extends StatelessWidget {
  const RecordingButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: 100,
      width: 100,
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(
        isRecording ? 25 : 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: isRecording ? 8 : 3,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
        ),
        child: MaterialButton(
          onPressed: onPressed,
          shape: const CircleBorder(),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}