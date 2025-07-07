import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomCircularProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  const CustomCircularProgressIndicator({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const size = 200.0;
    const TWO_PI = 3.14 * 2;
    int percentage = (progress * 100).ceil();
    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          ShaderMask(
            shaderCallback: (rect) {
              return SweepGradient(
                startAngle: 0.0,
                endAngle: TWO_PI,
                stops: [progress, progress],
                center: Alignment.center,
                colors: [Colors.purple, Colors.grey.withAlpha(55)],
              ).createShader(rect);
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage("assets/radial_scale.png"),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: size - 40,
              height: size - 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text("$percentage", style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
