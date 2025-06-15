import 'package:flutter/material.dart';

class ShowText extends StatelessWidget {
  final List<Map<String, dynamic>> responseSegments;

  const ShowText(this.responseSegments, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenHeight = screenSize.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcript'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        color: Colors.white,
        height: screenHeight - 100,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: responseSegments.isEmpty
            ? const Center(child: Text("No transcript available"))
            : RawScrollbar(
                thumbColor: Theme.of(context).primaryColor,
                radius: const Radius.circular(20),
                thickness: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: responseSegments.map((segment) {
                      final speaker = segment['speaker'];
                      final start = segment['start'].toStringAsFixed(2);
                      final end = segment['end'].toStringAsFixed(2);
                      final text = segment['text'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$speaker [$start - $end s]:\n',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: '$text\n',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
    );
  }
}
