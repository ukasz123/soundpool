import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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

  int _alarmSoundStreamId;
  int _cheeringStreamId = -1;

  String get _cheeringUrl => kIsWeb ? '/c-c-1.mp3' : 'https://raw.githubusercontent.com/ukasz123/soundpool/feature/web_support/example/web/c-c-1.mp3';

  void initState(){
    _soundId = _loadSound();
    _cheeringId = _loadCheering();
  }
  double _volume = 1.0;
  double _rate = 1.0;
  Future<int> _soundId;
  Future<int> _cheeringId;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: Center(
          child: SizedBox(
            width: kIsWeb ? 450: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rolling dices'),
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  RaisedButton(
                    onPressed: _playSound,
                    child: Text("Play"),
                    ),
                    SizedBox(width:8),
                  RaisedButton(
                    onPressed: _pauseSound,
                    child: Text("Pause"),
                    ),
                    SizedBox(width:8),
                  RaisedButton(
                    onPressed: _stopSound,
                    child: Text("Stop"),
                    ),
                ],
              ),
                    SizedBox(height:8),
              RaisedButton(
            onPressed: _playCheering,
            child: Text("Play cheering"),
          ),
            SizedBox(height: 4),
              Text('Set rate '),
              Row(children:[Expanded(child:Slider.adaptive(
                min: 0.5, max: 2.0,
                value: _rate,
                onChanged: (newRate){
                  setState((){_rate = newRate;});
                  _updateCheeringRate();
                },
              ),), Text('${_rate.toStringAsFixed(3)}'),]),
              SizedBox(height: 8.0),
              Text('Volume'),
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
    return await _soundpool.loadUri(_cheeringUrl);
  }

  Future<void> _playSound() async {
    var _alarmSound = await _soundId;
    _alarmSoundStreamId = await _soundpool.play(_alarmSound);
  }

  Future<void> _pauseSound() async {
    if (_alarmSoundStreamId != null){
      await _soundpool.pause(_alarmSoundStreamId);
    }
  }

  Future<void> _stopSound() async {
    if (_alarmSoundStreamId != null){
      await _soundpool.stop(_alarmSoundStreamId);
    }
  }

  Future<void> _playCheering() async {
    
    var _sound = await _cheeringId;
    _cheeringStreamId = await _soundpool.play(_sound, rate: _rate,);
  }

  Future<void> _updateCheeringRate() async {
    if (_cheeringStreamId > 0){
      await _soundpool.setRate(streamId: _cheeringStreamId, playbackRate: _rate);
    }
  }

  Future<void> _updateVolume(newVolume) async{
    // if (_alarmSound >= 0){
      var _cheeringSound = await _cheeringId;
      _soundpool.setVolume(soundId: _cheeringSound, volume: newVolume);
    // }
  }
}
