import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:mini_hack_flutter/screens/wake_up_game.dart';

class AlarmClockScreen extends StatefulWidget {
  final String title;
  
  const AlarmClockScreen({
    super.key,
    required this.title,
  });

  @override
  State<AlarmClockScreen> createState() => _AlarmClockScreenState();
}

class _AlarmClockScreenState extends State<AlarmClockScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAlarmSet = false;
  List<TimeOfDay> _alarms = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    await _audioPlayer.setSource(AssetSource('alarm.mp3'));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the alarm sound
  }

  @override
  void dispose() {
    _timer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        _checkAlarm();
      });
    });
  }

  void _checkAlarm() {
    if (_isAlarmSet) {
      for (var alarm in _alarms) {
        if (alarm.hour == _currentTime.hour && 
            alarm.minute == _currentTime.minute && 
            _currentTime.second == 0) {
          _playAlarm();
          _showAlarmDialog();
        }
      }
    }
  }

  Future<void> _playAlarm() async {
    if (!_isPlaying) {
      await _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _stopAlarm() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      await _audioPlayer.seek(Duration.zero);
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _showAlarmDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(16.0), 
          title: const Text('Wake Up!'),
          content: WakeUpGame(
          onGameComplete: () {
            _stopAlarm();
            _alarms.removeAt(0);
            Navigator.of(context).pop();
          },
        ),
          actions: <Widget>[
            TextButton(
              child: const Text('Snooze'),
              onPressed: () {
                _stopAlarm();
                Navigator.of(context).pop();
                // Add 5 minutes to the current alarm
                TimeOfDay snoozeTime = TimeOfDay(
                  hour: (_currentTime.hour + ((_currentTime.minute + 1) ~/ 60)) % 24,
                  minute: (_currentTime.minute + 1) % 60,
                );
                setState(() {
                  _alarms.add(snoozeTime);
                  _alarms.sort((a, b) {
                    // Convert TimeOfDay to minutes since midnight for comparison
                    int aMinutes = a.hour * 60 + a.minute;
                    int bMinutes = b.hour * 60 + b.minute;
                    return aMinutes.compareTo(bMinutes);
                  });
                });
              },
            ),
            // TextButton(
            //   child: const Text('Stop'),
            //   onPressed: () {
            //     _stopAlarm();
            //     Navigator.of(context).pop();
            //   },
            // ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _alarms.add(_selectedTime);
        _alarms.sort((a, b) {
          // Convert TimeOfDay to minutes since midnight for comparison
          int aMinutes = a.hour * 60 + a.minute;
          int bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });
        _isAlarmSet = true;
      });
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _formatTime(_currentTime),
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${_currentTime.day}/${_currentTime.month}/${_currentTime.year}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 40),
              if (_alarms.isNotEmpty) ...[
                const Text(
                  'Active Alarms:',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                ..._alarms.map((alarm) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                )).toList(),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                ),
                onPressed: () => _selectTime(context),
                child: const Text(
                  'Set Alarm',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}