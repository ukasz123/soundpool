import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:soundpool/soundpool.dart';

Soundpool _soundpool;
int _alarmSound = -1;

Future<void> main() async {
  _soundpool = Soundpool();
  runApp(SimpleApp());
}

class SimpleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: Center(
          child: RaisedButton(
            onPressed: _playSound,
            child: Text("Play sound"),
          ),
        ),
      ),
    );
  }

  void _playSound() async {
    if (_alarmSound < 0) {
      _alarmSound = await _soundpool.loadAndPlayUri(
          "https://github.com/ukasz123/soundpool/raw/master/example/sounds/dices.m4a");
    } else {
      _soundpool.play(_alarmSound);
    }
  }
}
