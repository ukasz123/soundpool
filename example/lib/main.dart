import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';

Soundpool _soundpool;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _soundpool = Soundpool();
  runApp(SimpleApp());
}

class SimpleApp extends StatefulWidget {
  SimpleApp({Key key}) : super(key: key);

  @override
  _SimpleAppState createState() => _SimpleAppState();
}

class _SimpleAppState extends State<SimpleApp> {

  void initState(){
    _soundId = _loadSound();
    _cheeringId = _loadCheering();
  }
  double _volume = 1.0;
  Future<int> _soundId;
  Future<int> _cheeringId;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: Center(
          child: SizedBox(
            width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RaisedButton(
            onPressed: _playSound,
            child: Text("Play sound"),
          ),
              RaisedButton(
            onPressed: _playCheering,
            child: Text("Play cheering"),
          ),
            Slider.adaptive(
              value: _volume,
              onChanged:(newVolume) {
                setState((){_volume = newVolume;});
                _updateVolume(newVolume);
              }
            ),
          ],
          ),
          ),
        ),
      ),
    );
  }

  Future<int> _loadSound() async {
    var asset = await rootBundle.load("sounds/do-you-like-it.wav");
      return await _soundpool.load(asset);
  }

  Future<int> _loadCheering() async {
    return await _soundpool.loadUri('/c-c-1.mp3');
  }

  Future<void> _playSound() async {
    // if (_alarmSound < 0) {
    //   var asset = await rootBundle.load("sounds/do-you-like-it.wav");
    //   _alarmSound = await _soundpool.loadAndPlay(asset);
    // } else {
    //   _soundpool.play(_alarmSound);
    // }
    var _alarmSound = await _soundId;
    _soundpool.play(_alarmSound);
  }
  Future<void> _playCheering() async {
    
    var _sound = await _cheeringId;
    _soundpool.play(_sound);
  }

  Future<void> _updateVolume(newVolume) async{
    // if (_alarmSound >= 0){
      var _alarmSound = await _cheeringId;
      _soundpool.setVolume(soundId: _alarmSound, volume: newVolume);
    // }
  }
}
