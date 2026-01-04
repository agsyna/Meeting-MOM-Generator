import 'package:flutter/material.dart';
import 'package:meeting_gist/models/transcription_result.dart';

/// Widget to display transcription results summary
class ResultsSummary extends StatelessWidget {
  final TranscriptionResult result;

  const ResultsSummary({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final speakers = result.speakers;
    final totalDuration = result.segments.isNotEmpty
        ? result.segments.last.endTime
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transcription Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    context,
                    'Total Duration:',
                    _formatDuration(totalDuration),
                  ),
                  _buildSummaryRow(
                    context,
                    'Total Segments:',
                    '${result.segments.length}',
                  ),
                  _buildSummaryRow(
                    context,
                    'Unique Speakers:',
                    '${speakers.length}',
                  ),
                  _buildSummaryRow(
                    context,
                    'Processing Time:',
                    '${result.processingTime.inSeconds}s',
                  ),
                  _buildSummaryRow(
                    context,
                    'Model:',
                    result.modelVersion,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Speakers Section
          if (speakers.isNotEmpty) ...[
            Text(
              'Speakers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._buildSpeakerCards(context, speakers),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSpeakerCards(BuildContext context, List<String> speakers) {
    return speakers.map((speaker) {
      final speakerSegments = result.segments
          .where((s) => s.speaker == speaker)
          .toList();
      
      final speakerDuration = speakerSegments.fold<double>(
        0,
        (sum, s) => sum + (s.endTime - s.startTime),
      );

      final wordCount = speakerSegments.fold<int>(
        0,
        (sum, s) => sum + s.text.split(' ').length,
      );

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSpeakerColor(speaker),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      speaker.isNotEmpty ? speaker[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          '${speakerSegments.length} segments',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duration: ${_formatDuration(speakerDuration)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    'Words: $wordCount',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _getSpeakerColor(String speaker) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.teal,
    ];

    final hash = speaker.hashCode.abs();
    return colors[hash % colors.length];
  }

  String _formatDuration(double seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }
}
