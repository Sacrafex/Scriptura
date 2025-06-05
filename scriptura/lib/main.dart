import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    title: 'Scripture Quiz',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    home: const ScriptureQuiz(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

class ScriptureQuiz extends StatefulWidget {
  const ScriptureQuiz({super.key});

  @override
  State<ScriptureQuiz> createState() => _ScriptureQuizState();
}

class _ScriptureQuizState extends State<ScriptureQuiz>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<int> _typewriterAnimation;

  List<Map<String, dynamic>> _verses = [];
  int _currentIndex = 0;
  bool _isCatholicEdition = false;
  String _feedback = '';
  String _source = '';
  bool _showButtons = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVerses().then((_) {
        setState(() {
          _currentIndex = 0;
          _feedback = '';
          _source = '';
          final verse = _verses[_currentIndex][_isCatholicEdition ? 'nsrv_ce' : 'kjv'];
          _typewriterAnimation = IntTween(begin: 0, end: verse.length).animate(_controller);
          _controller.forward(from: 0);
        });
      });
    });
  }

  Future<void> _loadVerses() async {
    final String data = await rootBundle.loadString('assets/verses.json');
    setState(() {
      _verses = List<Map<String, dynamic>>.from(json.decode(data));
      _verses.shuffle(Random());
      _typewriterAnimation = IntTween(begin: 0, end: _verses[_currentIndex][_isCatholicEdition ? 'nsrv_ce' : 'kjv'].length).animate(_controller);
    });
  }

  void _checkAnswer(bool isScripture) {
    final correctAnswer = _verses[_currentIndex]['isScripture'] as bool;
    setState(() {
      _showButtons = false;
      if (isScripture == correctAnswer) {
        _feedback = 'Correct!';
        _source = _verses[_currentIndex]['source'] ?? 'Unknown Source';
      } else {
        _feedback = 'Incorrect. Try again.';
        _source = '';
      }
      _controller.forward(from: 0);
    });
  }

  void _nextVerse() {
    setState(() {
      do {
        _currentIndex = (_currentIndex + 1) % _verses.length;
      } while (!_isCatholicEdition && _verses[_currentIndex]['isCatholic'] == true);

      _feedback = '';
      _source = '';
      _showButtons = true;

      final verse = _verses[_currentIndex][_isCatholicEdition ? 'nsrv_ce' : 'kjv'];
      _typewriterAnimation = IntTween(begin: 0, end: verse.length).animate(_controller);
    });
  }

  void _toggleEdition() {
    setState(() {
      _isCatholicEdition = !_isCatholicEdition;

      final verse = _verses[_currentIndex][_isCatholicEdition ? 'nsrv_ce' : 'kjv'];
      _typewriterAnimation = IntTween(begin: 0, end: verse.length).animate(_controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verses.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final verse = _currentIndex >= 0 ? _verses[_currentIndex][_isCatholicEdition ? 'nsrv_ce' : 'kjv'] : '';
    final bookName = _currentIndex >= 0 ? _verses[_currentIndex]['source']?.split(' ')[0] ?? 'Unknown' : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scriptura',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentIndex == -1) ...[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    final verse = _verses[_currentIndex][_isCatholicEdition ? 'nsrv_ce' : 'kjv'];
                    _typewriterAnimation = IntTween(begin: 0, end: verse.length).animate(_controller);
                    _controller.forward(from: 0);
                  });
                },
                child: Text('Start'),
              ),
            ] else ...[
              FadeTransition(
                opacity: _animation,
                child: Text(
                  _feedback,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'The Book Of',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                bookName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 20),
              AnimatedBuilder(
                animation: _typewriterAnimation,
                builder: (context, child) {
                  final visibleText = verse.substring(0, _typewriterAnimation.value);
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      visibleText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              if (_source.isNotEmpty)
                Text(
                  _source,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                ),
              SizedBox(height: 20),
              if (_showButtons) Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _checkAnswer(true),
                    child: Text('Yes'),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _checkAnswer(false),
                    child: Text('No'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _nextVerse,
                child: Text('Next Verse'),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _toggleEdition,
                child: Text(
                  _isCatholicEdition ? 'Catholic Edition' : 'Protestant Edition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
