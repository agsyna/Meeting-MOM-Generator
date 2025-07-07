import 'package:flutter/material.dart';

class ShowText extends StatelessWidget {
  final List<Map<String, dynamic>> responseSegments;

  const ShowText(this.responseSegments, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Transcript',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                ],
              ),
            ),
          ),
        ),
      ),
      body: responseSegments.isEmpty
          ? _buildEmptyState()
          : _buildTranscriptContent(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.transcribe,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No transcript available",
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF1A1D29),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a conversation to see the transcript",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final segment = responseSegments[index];
                    return _buildTranscriptSegment(segment, index);
                  },
                  childCount: responseSegments.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.record_voice_over,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  '${responseSegments.length} segments',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTotalDuration(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSegment(Map<String, dynamic> segment, int index) {
    final speaker = segment['speaker'] ?? 'Unknown';
    final start = segment['start']?.toStringAsFixed(2) ?? '0.00';
    final end = segment['end']?.toStringAsFixed(2) ?? '0.00';
    final text = segment['text'] ?? '';

    final speakerColor = _getSpeakerColor(speaker);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  speakerColor,
                  speakerColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: speakerColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                speaker.isNotEmpty ? speaker[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Enhanced content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speaker name and timestamp row
                Row(
                  children: [
                    Text(
                      speaker,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: speakerColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: speakerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: speakerColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_formatTime(start)} - ${_formatTime(end)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: speakerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Enhanced text content
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1D29),
                      height: 1.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpeakerColor(String speaker) {
    final colors = [
      const Color(0xFF667EEA), // Blue
      const Color(0xFF48BB78), // Green
      const Color(0xFF9F7AEA), // Purple
      const Color(0xFFF56565), // Red
      const Color(0xFF38B2AC), // Teal
      const Color(0xFFED8936), // Orange
      const Color(0xFFEC4899), // Pink
      const Color(0xFF4299E1), // Light Blue
    ];
    
    final hash = speaker.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _formatTime(String timeStr) {
    final seconds = double.tryParse(timeStr) ?? 0.0;
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    
    if (minutes > 0) {
      return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${remainingSeconds}s';
    }
  }

  String _getTotalDuration() {
    if (responseSegments.isEmpty) return '0:00';
    
    final lastSegment = responseSegments.last;
    final totalSeconds = lastSegment['end']?.toDouble() ?? 0.0;
    
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).floor();
    
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}