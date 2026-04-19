import 'package:flutter/material.dart';
import 'dictation_item.dart';
import 'dictation_list.dart';
import 'tts_service.dart';

class SessionScreen extends StatefulWidget {
  final DictationList list;

  const SessionScreen({super.key, required this.list});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late List<DictationItem> _shuffledItems;
  final TtsService _ttsService = TtsService();
  late Future<void> _initTtsFuture;

  int _currentIndex = 0;
  double _speechRate = 0.75;
  bool _hasStarted = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // Create a copy of the list and shuffle it
    _shuffledItems = List.from(widget.list.items)..shuffle();
    _initTtsFuture = _initTts();
  }

  Future<void> _initTts() async {
    await _ttsService.stop(); // Stop any pending speech from previous session
    await _ttsService.ensureInitialized();
    await _ttsService.flutterTts.setLanguage(widget.list.languageCode);
    await _ttsService.flutterTts.setSpeechRate(_speechRate);
  }

  @override
  void dispose() {
    // Note: Don't stop it here if we want current word to finish, 
    // but usually, popping means we want to be quiet.
    _ttsService.stop(); 
    super.dispose();
  }

  Future<void> _speakCurrentItem() async {
    if (_currentIndex < _shuffledItems.length) {
      await _initTtsFuture; // Ensure TTS is ready before speaking
      await _ttsService.speak(_shuffledItems[_currentIndex].text);
    }
  }

  Future<void> _startSession() async {
    // Warm up the TTS engine on the first user interaction (critical for Web)
    await _initTtsFuture;
    
    // Some browsers need a non-empty string to truly unlock audio
    // and a brief moment to stabilize after the first interaction.
    await _ttsService.speak(' '); 
    await Future.delayed(const Duration(milliseconds: 300)); // Slightly longer delay for stability

    setState(() {
      _hasStarted = true;
    });
    
    // Trigger the first actual word
    await _speakCurrentItem();
  }

  void _nextItem() {
    if (_currentIndex < _shuffledItems.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _speakCurrentItem();
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isFinished ? 'Results' : 'Spelling/Dictation Session'),
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isFinished) {
      return _buildResults();
    }

    if (!_hasStarted) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get your pen and paper ready!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Spelling/Dictation'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, inherit: false),
            ),
          ),
        ],
      );
    }

    // Active Session UI
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Word ${_currentIndex + 1} of ${_shuffledItems.length}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 48),
        OutlinedButton.icon(
          onPressed: _speakCurrentItem,
          icon: const Icon(Icons.replay),
          label: const Text('Repeat'),
        ),
        const SizedBox(height: 64),
        FilledButton(
          onPressed: _nextItem,
          child: Text(
            _currentIndex < _shuffledItems.length - 1
                ? 'Next Word'
                : 'Finish Session',
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      itemCount: _shuffledItems.length,
      itemBuilder: (context, index) {
        final item = _shuffledItems[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(item.text, style: const TextStyle(fontSize: 18)),
        );
      },
    );
  }
}
