import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechSampleApp extends StatefulWidget {
  const SpeechSampleApp({Key? key}) : super(key: key);

  @override
  State<SpeechSampleApp> createState() => _SpeechSampleAppState();
}

class _SpeechSampleAppState extends State<SpeechSampleApp>
    with TickerProviderStateMixin {
  bool _hasSpeech = false;
  bool _logEvents = false;
  bool _onDevice = false;
  final TextEditingController _pauseForController =
      TextEditingController(text: '3');
  final TextEditingController _listenForController =
      TextEditingController(text: '30');
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Pulse animation for the microphone
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Wave animation for sound visualization
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: _logEvents,
      );
      if (hasSpeech) {
        _localeNames = await speech.locales();
        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
        _fadeController.forward(); // Trigger fade animation
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernAppBar(),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Initialize section
                      _buildInitializationCard(),
                      const SizedBox(height: 20),
                      
                      // Main speech recognition area
                      _buildSpeechRecognitionArea(),
                      const SizedBox(height: 20),
                      
                      // Control buttons
                      _buildControlButtons(),
                      const SizedBox(height: 20),
                      
                      // Settings panel
                      _buildSettingsPanel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Live Transcription',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: speech.isListening ? Colors.green : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: speech.isListening ? Colors.white : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  speech.isListening ? 'Listening' : 'Idle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _buildInitializationCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _hasSpeech ? Icons.check_circle : Icons.mic_none,
            size: 48,
            color: _hasSpeech ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            _hasSpeech ? 'Speech Recognition Ready' : 'Initialize Speech Recognition',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          if (!_hasSpeech) ...[
            const Text(
              'Tap to enable speech recognition',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: initSpeechState,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Initialize'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeechRecognitionArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAnimatedMicrophone(),
          const SizedBox(height: 24),
          
          _buildRecognizedText(),
          const SizedBox(height: 16),
          
          if (lastError.isNotEmpty) _buildErrorDisplay(),
        ],
      ),
    );
  }

  Widget _buildAnimatedMicrophone() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing rings
            for (int i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Container(
                    width: 120 + (i * 30) + (level * 2),
                    height: 120 + (i * 30) + (level * 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF667eea).withOpacity(
                          speech.isListening ? 0.3 - (i * 0.1) : 0.1,
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
            
            // Main microphone container
            Transform.scale(
              scale: speech.isListening ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  speech.isListening ? Icons.mic : Icons.mic_none,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecognizedText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Recognized Speech',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              lastWords.isEmpty ? 'Start speaking to see transcription...' : lastWords,
              style: TextStyle(
                fontSize: 16,
                color: lastWords.isEmpty ? Colors.grey[500] : const Color(0xFF2D3748),
                fontWeight: lastWords.isEmpty ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastError,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Start button
          Expanded(
            child: _buildControlButton(
              icon: Icons.play_arrow,
              label: 'Start',
              color: Colors.green,
              onPressed: !_hasSpeech || speech.isListening ? null : startListening,
            ),
          ),
          const SizedBox(width: 12),
          
          // Stop button
          Expanded(
            child: _buildControlButton(
              icon: Icons.stop,
              label: 'Stop',
              color: Colors.orange,
              onPressed: speech.isListening ? stopListening : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // Cancel button
          Expanded(
            child: _buildControlButton(
              icon: Icons.cancel,
              label: 'Cancel',
              color: Colors.red,
              onPressed: speech.isListening ? cancelListening : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey[300],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: onPressed != null ? 4 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Language selector
          _buildLanguageSelector(),
          const SizedBox(height: 16),
          
          // Duration controls
          _buildDurationControls(),
          const SizedBox(height: 16),
          
          // Checkboxes
          _buildCheckboxSettings(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.language, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          const Text(
            'Language:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _currentLocaleId.isEmpty ? null : _currentLocaleId,
              isExpanded: true,
              underline: Container(),
              onChanged: (selectedVal) => _switchLang(selectedVal),
              items: _localeNames
                  .map(
                    (localeName) => DropdownMenuItem(
                      value: localeName.localeId,
                      child: Text(localeName.name),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationControls() {
    return Row(
      children: [
        // Pause for control
        Expanded(
          child: _buildDurationField(
            icon: Icons.pause,
            label: 'Pause For',
            controller: _pauseForController,
            suffix: 'sec',
          ),
        ),
        const SizedBox(width: 12),
        // Listen for control
        Expanded(
          child: _buildDurationField(
            icon: Icons.timer,
            label: 'Listen For',
            controller: _listenForController,
            suffix: 'sec',
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: suffix,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxSettings() {
    return Row(
      children: [
        Expanded(
          child: _buildCheckboxTile(
            icon: Icons.phone_android,
            label: 'On Device',
            value: _onDevice,
            onChanged: _switchOnDevice,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCheckboxTile(
            icon: Icons.bug_report,
            label: 'Log Events',
            value: _logEvents,
            onChanged: _switchLogging,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF667eea),
          ),
        ],
      ),
    );
  }

  void startListening() {
    _logEvent('start listening');
    lastWords = '';
    lastError = '';
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _fadeController.forward();
    
    final pauseFor = int.tryParse(_pauseForController.text);
    final listenFor = int.tryParse(_listenForController.text);
    final options = SpeechListenOptions(
        onDevice: _onDevice,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true);
    
    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: listenFor ?? 30),
      pauseFor: Duration(seconds: pauseFor ?? 3),
      localeId: _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      listenOptions: options,
    );
    setState(() {});
  }

  void stopListening() {
    _logEvent('stop');
    speech.stop();
    _pulseController.stop();
    _waveController.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    _logEvent('cancel');
    speech.cancel();
    _pulseController.stop();
    _waveController.stop();
    setState(() {
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    _logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
        'Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = status;
    });
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      debugPrint('$eventTime $eventDescription');
    }
  }

  void _switchLogging(bool? val) {
    setState(() {
      _logEvents = val ?? false;
    });
  }

  void _switchOnDevice(bool? val) {
    setState(() {
      _onDevice = val ?? false;
    });
  }
}