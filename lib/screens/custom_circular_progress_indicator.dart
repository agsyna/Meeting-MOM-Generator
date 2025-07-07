import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomCircularProgressIndicator extends StatefulWidget {
  @override
  State<CustomCircularProgressIndicator> createState() {
    return _CustomCircularProgressIndicatorState();
  }
}

const TWO_PI = 3.14 * 2;

class _CustomCircularProgressIndicatorState
    extends State<CustomCircularProgressIndicator> {
  final size = 200.0;

  Widget build(context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 15),
      builder: (content, value, child) {
        int percentage = (value*100).ceil();
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
                    stops: [value, value],
                    //no of stops = no. colors
                    //0.0, 0.5,0.5,1.0
                    center: Alignment.center,
                    colors: [Colors.purple, Colors.grey.withAlpha(55)],
                  ).createShader(rect);
                },
                
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage
                    (image: 
                    AssetImage("assets/radial_scale.png"))             
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
      },
    );
  }
}
