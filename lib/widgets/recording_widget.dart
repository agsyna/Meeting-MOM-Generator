


import 'dart:async';

import 'package:flutter/material.dart';

class RecordingWidget extends StatefulWidget{
  const RecordingWidget({super.key});
  @override
  State<RecordingWidget> createState() {
    return _RecordingWidgetState();
  }
}

class _RecordingWidgetState extends State<RecordingWidget>{

  final List<double> _heights = [0.05, 0.07, 0.1, 0.07, 0.05];
  Timer? _timer;

  @override
  void initState() {
    _startAnimating();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimating() {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _heights.add(_heights.removeAt(0));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _heights.map((height) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20,
            height: MediaQuery.sizeOf(context).height * height,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(50),
            ),
          );
        }).toList(),
      ),
    );
  }
}

