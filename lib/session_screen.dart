import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dictation_item.dart';
import 'dictation_list.dart';

class SessionScreen extends StatefulWidget {
  final DictationList list;

  const SessionScreen({super.key, required this.list});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late List<DictationItem> _shuffledItems;
  late FlutterTts _flutterTts;

  int _currentIndex = 0;
  double _speechRate = 0.5;
  bool _hasStarted = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // Create a copy of the list and shuffle it
    _shuffledItems = List.from(widget.list.items)..shuffle();
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage(widget.list.languageCode);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakCurrentItem() async {
    if (_currentIndex < _shuffledItems.length) {
      await _flutterTts.speak(_shuffledItems[_currentIndex].text);
    }
  }

  void _startSession() {
    setState(() {
      _hasStarted = true;
    });
    _speakCurrentItem();
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

  Widget _buildSpeedSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Speaking Speed: ${_speechRate.toStringAsFixed(2)}x'),
          Slider(
            value: _speechRate,
            min: 0.25,
            max: 1.5,
            divisions: 5, // 0.25, 0.5, 0.75, 1.0, 1.25, 1.5
            label: '${_speechRate.toStringAsFixed(2)}x',
            onChanged: (value) {
              setState(() => _speechRate = value);
              _flutterTts.setSpeechRate(_speechRate);
            },
          ),
        ],
      ),
    );
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
          const SizedBox(height: 48),
          _buildSpeedSlider(),
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
        const SizedBox(height: 48),
        _buildSpeedSlider(),
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
