import 'package:flutter/material.dart';
import 'package:meeting_gist/models/transcription_result.dart';

/// Widget to display a single transcription segment
class SegmentTile extends StatelessWidget {
  final TranscriptionSegment segment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SegmentTile({
    Key? key,
    required this.segment,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSpeakerColor(segment.speaker),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            segment.speaker.isNotEmpty ? segment.speaker[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          segment.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Speaker: ${segment.speaker}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              segment.formattedTimestamp,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(segment.confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _getConfidenceColor(segment.confidence),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// Widget to display all transcription segments
class SegmentsList extends StatelessWidget {
  final List<TranscriptionSegment> segments;
  final bool isLoading;
  final ScrollController? scrollController;

  const SegmentsList({
    Key? key,
    required this.segments,
    this.isLoading = false,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (segments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transcription segments yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: segments.length,
      itemBuilder: (context, index) {
        return SegmentTile(
          segment: segments[index],
          onLongPress: () {
            _showSegmentDetails(context, segments[index]);
          },
        );
      },
    );
  }

  void _showSegmentDetails(BuildContext context, TranscriptionSegment segment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Segment ${segment.id + 1}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Speaker:', segment.speaker),
                _buildDetailRow('Time:', segment.formattedTimestamp),
                _buildDetailRow(
                  'Duration:',
                  '${(segment.endTime - segment.startTime).toStringAsFixed(2)}s',
                ),
                _buildDetailRow(
                  'Confidence:',
                  '${(segment.confidence * 100).toStringAsFixed(1)}%',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                const Text(
                  'Text:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(segment.text),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
