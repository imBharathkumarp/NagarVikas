import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  static final FlutterTts _globalTts = FlutterTts();
  static String? _currentSpeakingTileId;
  static final Map<String, _ExpandableTileState> _activeTiles = {};
  static bool _isInitialized = false;

  static void _initializeGlobalTts() {
    if (_isInitialized) return;

    _globalTts.setStartHandler(() {
      if (_currentSpeakingTileId != null && _activeTiles.containsKey(_currentSpeakingTileId)) {
        _activeTiles[_currentSpeakingTileId!]?._onTtsStart();
      }
    });

    _globalTts.setCompletionHandler(() {
      if (_currentSpeakingTileId != null && _activeTiles.containsKey(_currentSpeakingTileId)) {
        _activeTiles[_currentSpeakingTileId!]?._onTtsComplete();
      }
      _currentSpeakingTileId = null;
    });

    _globalTts.setErrorHandler((msg) {
      if (_currentSpeakingTileId != null && _activeTiles.containsKey(_currentSpeakingTileId)) {
        _activeTiles[_currentSpeakingTileId!]?._onTtsError();
      }
      _currentSpeakingTileId = null;
    });

    _isInitialized = true;
  }

  static void registerTile(String tileId, _ExpandableTileState tile) {
    _activeTiles[tileId] = tile;
    _initializeGlobalTts();
  }

  static void unregisterTile(String tileId) {
    if (_currentSpeakingTileId == tileId) {
      _globalTts.stop();
      _currentSpeakingTileId = null;
    }
    _activeTiles.remove(tileId);
  }

  static Future<void> startSpeaking(String tileId, String text) async {
    // Stop current speaking tile if different
    if (_currentSpeakingTileId != null && _currentSpeakingTileId != tileId) {
      if (_activeTiles.containsKey(_currentSpeakingTileId)) {
        _activeTiles[_currentSpeakingTileId!]?._onTtsStoppedByOther();
      }
    }

    _currentSpeakingTileId = tileId;
    await _globalTts.stop();
    await _globalTts.speak(text);
  }

  static Future<void> stopSpeaking(String tileId) async {
    if (_currentSpeakingTileId == tileId) {
      await _globalTts.stop();
      _currentSpeakingTileId = null;
      if (_activeTiles.containsKey(tileId)) {
        _activeTiles[tileId]?._onTtsStopped();
      }
    }
  }

  static bool isSpeaking(String tileId) {
    return _currentSpeakingTileId == tileId;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor:
        themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: Text('About the App'),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: ListView(
            children: [
              _buildQuestionTile(
                'what_is_nagarvikas',
                'What is NagarVikas?',
                'NagarVikas is a civic issue complaint application designed to bridge the gap between citizens and municipal authorities. It allows citizens to easily report and track the resolution of civic issues like garbage disposal, potholes, water supply issues, and more.',
              ),
              _buildQuestionTile(
                'what_do_we_do',
                'What do we do?',
                'We provide an easy and convenient platform for reporting civic issues, enabling the authorities to act on them promptly. Our mission is to make urban living cleaner and more efficient by empowering citizens to take action on the problems they encounter.',
              ),
              _buildQuestionTile(
                'what_do_we_offer',
                'What do we offer?',
                'Our app offers a variety of services, including issue reporting, live status tracking, and automated notifications. You can submit complaints about various civic problems, track the progress, and receive updates on the resolution.',
              ),
              _buildQuestionTile(
                'features_of_nagarvikas',
                'What are the features of NagarVikas?',
                '• Easy complaint submission\n• Track complaint status in real time\n• Notifications and reminders for pending issues\n• User-friendly interface\n• Fast and reliable issue resolution system',
              ),
              _buildQuestionTile(
                'who_developed_nagarvikas',
                'Who developed NagarVikas?',
                'nagarvikas was developed by a passionate team aiming to improve civic engagement and urban infrastructure. We believe technology can solve problems more efficiently and make a positive impact on the community.',
              ),
              _buildQuestionTile(
                'how_can_i_contact_you',
                'How can I contact you?',
                'For more information or support, feel free to reach out to us at support@nagarvikas.com. We value your feedback and are always here to help.',
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuestionTile(String tileId, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: _ExpandableTile(
        tileId: tileId,
        question: question,
        answer: answer,
      ),
    );
  }
}

class _ExpandableTile extends StatefulWidget {
  final String tileId;
  final String question;
  final String answer;

  const _ExpandableTile({
    required this.tileId,
    required this.question,
    required this.answer,
  });

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> with AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  bool _isSpeaking = false;

  @override
  bool get wantKeepAlive => true; // This prevents disposal during scrolling

  @override
  void initState() {
    super.initState();
    _AboutAppPageState.registerTile(widget.tileId, this);
  }

  @override
  void dispose() {
    _AboutAppPageState.unregisterTile(widget.tileId);
    super.dispose();
  }

  void _onTtsStart() {
    if (mounted) {
      setState(() {
        _isSpeaking = true;
      });
    }
  }

  void _onTtsComplete() {
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isExpanded = false; // Auto-contract when speech completes
      });
    }
  }

  void _onTtsError() {
    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  void _onTtsStoppedByOther() {
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        // Keep expanded when stopped by another tile
      });
    }
  }

  void _onTtsStopped() {
    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      // Stop TTS
      await _AboutAppPageState.stopSpeaking(widget.tileId);
    } else {
      // Start TTS
      if (!_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
      }

      String textToSpeak = "${widget.question}. ${widget.answer}";
      await _AboutAppPageState.startSpeaking(widget.tileId, textToSpeak);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black26
                  : Colors.grey.withAlpha((0.2 * 255).toInt()),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question and TTS Controls section (inline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.question,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        InkWell(
                          onTap: _toggleTts,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(6.0),
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              child: Icon(
                                _isSpeaking ? Icons.stop : Icons.volume_up,
                                key: ValueKey(_isSpeaking),
                                color: _isSpeaking
                                    ? (themeProvider.isDarkMode ? Colors.red[300] : Colors.red[600])
                                    : (themeProvider.isDarkMode ? Colors.white70 : Colors.black54),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        if (_isSpeaking)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              '(Speaking...)',
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                        size: 30,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Expandable answer section
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  textAlign: TextAlign.justify,
                ),
              )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }
}
