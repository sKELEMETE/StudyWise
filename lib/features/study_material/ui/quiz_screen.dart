import 'package:flutter/material.dart';

class QuizTab extends StatefulWidget {
  final String folderName;
  final String userId;

  const QuizTab({
    super.key,
    required this.folderName,
    required this.userId,
  });

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  int index = 0;
  int score = 0;

  final questions = [
    {
      'q': 'What is Flutter?',
      'a': ['SDK', 'IDE', 'Language'],
      'correct': 0
    },
    {
      'q': 'Dart is made by?',
      'a': ['Google', 'Meta', 'Apple'],
      'correct': 0
    },
  ];

  void answer(int selected) {
    if (selected == questions[index]['correct']) score++;

    if (index < questions.length - 1) {
      setState(() => index++);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Score'),
          content: Text('$score / ${questions.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  index = 0;
                  score = 0;
                });
              },
              child: const Text('Restart'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[index];

    return Scaffold(
      appBar: AppBar(title: Text('Quiz: ${widget.folderName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(q['q'] as String, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ...(q['a'] as List<String>).asMap().entries.map((e) {
              return ElevatedButton(
                onPressed: () => answer(e.key),
                child: Text(e.value),
              );
            })
          ],
        ),
      ),
    );
  }
}