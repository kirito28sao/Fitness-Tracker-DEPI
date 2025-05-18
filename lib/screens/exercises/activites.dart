import 'package:flutter/material.dart';
import 'dart:async';

class ExerciseListScreen extends StatelessWidget {
  static const List<Map<String, dynamic>> exercises = [
    {
      'name': 'Running',
      'steps': [
        'Warm up for 5 minutes',
        'Run at a moderate pace for 20 minutes',
        'Cool down for 5 minutes'
      ],
      'icon': Icons.directions_run,
      'description':
          'Excellent exercise for improving fitness and burning calories',
      'duration': 1800, // 30 minutes in seconds
      'image': 'assets/images/running.jpg',
    },
    {
      'name': 'Jumping',
      'steps': [
        'Stand in an upright position',
        'Jump up with arms raised',
        'Repeat 20 times'
      ],
      'icon': Icons.fitness_center,
      'description':
          'Effective exercise for improving leg strength and heart health',
      'duration': 300, // 5 minutes in seconds
      'image': 'assets/images/jumping.jpg',
    },
    {
      'name': 'Push-ups',
      'steps': [
        'Lie on the ground',
        'Raise your body using your arms',
        'Lower slowly and repeat 15 times'
      ],
      'icon': Icons.sports_gymnastics,
      'description': 'Powerful exercise for strengthening chest and arm muscles',
      'duration': 180, // 3 minutes in seconds
      'image': 'assets/images/pushups.jpg',
    },
    {
      'name': 'Abdominal Exercises',
      'steps': ['Lie on your back', 'Raise your upper body', 'Repeat 20 times'],
      'icon': Icons.sports_martial_arts,
      'description': 'Core exercise for strengthening abdominal muscles',
      'duration': 240, // 4 minutes in seconds
      'image': 'assets/images/abs.jpg',
    }
  ];

  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    exercises[index]['image'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          exercises[index]['icon'],
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exercises[index]['name'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${exercises[index]['duration'] ~/ 60} min',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exercises[index]['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailScreen(
                                exerciseName: exercises[index]['name'],
                                steps: exercises[index]['steps'],
                                icon: exercises[index]['icon'],
                                gifPath: exercises[index]['image'],
                                duration: exercises[index]['duration'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Start Exercise'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseName;
  final String gifPath;
  final List<String> steps;
  final int duration;

  const ExerciseDetailScreen({
    Key? key,
    required this.exerciseName,
    required this.gifPath,
    required this.steps,
    required this.duration,
    required icon,
  }) : super(key: key);

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> with SingleTickerProviderStateMixin {
  late int _timeLeft;
  Timer? _timer;
  bool _isExerciseStarted = false;
  bool _isPaused = false;
  StateSetter? _dialogStateSetter;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.duration;
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dialogStateSetter = null;
    _progressController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    setState(() {
      _isExerciseStarted = true;
      _isPaused = false;
    });
    _showTimerDialog();
    _progressController.duration = Duration(seconds: _timeLeft);
    _progressController.reverse(from: 1.0);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
        _updateDialogState();
      } else {
        timer.cancel();
        _progressController.stop();
        setState(() {
          _isExerciseStarted = false;
          _timeLeft = widget.duration;
        });
        Navigator.of(context).pop();
        _showCompletionDialog();
      }
    });
  }

  void _updateDialogState() {
    if (_dialogStateSetter != null) {
      _dialogStateSetter!(() {});
    }
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
    });
    _updateDialogState();
    _timer?.cancel();
    _progressController.stop();
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    _updateDialogState();
    _progressController.duration = Duration(seconds: _timeLeft);
    _progressController.reverse(from: _timeLeft / widget.duration);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
        _updateDialogState();
      } else {
        timer.cancel();
        _progressController.stop();
        setState(() {
          _isExerciseStarted = false;
          _timeLeft = widget.duration;
        });
        Navigator.of(context).pop();
        _showCompletionDialog();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _timeLeft = widget.duration;
      _isPaused = false;
    });
    _updateDialogState();
    _timer?.cancel();
    _progressController.duration = Duration(seconds: widget.duration);
    _progressController.reverse(from: 1.0);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
        _updateDialogState();
      } else {
        timer.cancel();
        _progressController.stop();
        setState(() {
          _isExerciseStarted = false;
          _timeLeft = widget.duration;
        });
        Navigator.of(context).pop();
        _showCompletionDialog();
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _isExerciseStarted = false;
      _isPaused = false;
      _timeLeft = widget.duration;
    });
    _timer?.cancel();
    _progressController.stop();
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            _dialogStateSetter = setState;
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Exercise Timer'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _stopTimer();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 200,
                          width: 200,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressController.value,
                                strokeWidth: 20,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isPaused 
                                      ? Colors.orange 
                                      : Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(_timeLeft),
                                    style: const TextStyle(
                                      fontSize: 44,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!_isPaused)
                        IconButton(
                          icon: const Icon(Icons.pause, size: 30),
                          onPressed: _pauseTimer,
                          tooltip: 'Pause',
                          color: Colors.blue,
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.play_arrow, size: 30),
                          onPressed: _resumeTimer,
                          tooltip: 'Resume',
                          color: Colors.green,
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 30),
                        onPressed: _resetTimer,
                        tooltip: 'Reset',
                        color: Colors.orange,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop, size: 30),
                        onPressed: () {
                          _stopTimer();
                          Navigator.of(context).pop();
                        },
                        tooltip: 'Stop',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
    ).then((_) {
      _dialogStateSetter = null;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exercise Complete!'),
          content: const Text('Great job! You\'ve completed your exercise.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              widget.gifPath,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.fitness_center, size: 100),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exercise Steps:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.steps.map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isExerciseStarted ? null : _startTimer,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(_isExerciseStarted
                        ? 'Exercise in Progress...'
                        : 'Start Exercise'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
