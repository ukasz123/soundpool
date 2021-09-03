import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:soundpool_example/platform_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: SoundpoolInitializer()));
}

class SoundpoolInitializer extends StatefulWidget {
  @override
  _SoundpoolInitializerState createState() => _SoundpoolInitializerState();
}

class _SoundpoolInitializerState extends State<SoundpoolInitializer> {
  Soundpool? _pool;
  SoundpoolOptions _soundpoolOptions = SoundpoolOptions();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initPool(_soundpoolOptions);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pool == null) {
      return Material(
        child: Center(
          child: RaisedButton(
            onPressed: () => _initPool(_soundpoolOptions),
            child: Text("Init Soundpool"),
          ),
        ),
      );
    } else {
      return SimpleApp(
        pool: _pool!,
        onOptionsChange: _initPool,
      );
    }
  }

  void _initPool(SoundpoolOptions soundpoolOptions) {
    _pool?.dispose();
    setState(() {
      _soundpoolOptions = soundpoolOptions;
      _pool = Soundpool.fromOptions(options: _soundpoolOptions);
      print('pool updated: $_pool');
    });
  }
}

class SimpleApp extends StatefulWidget {
  final Soundpool pool;
  final ValueSetter<SoundpoolOptions> onOptionsChange;
  SimpleApp({Key? key, required this.pool, required this.onOptionsChange})
      : super(key: key);

  @override
  _SimpleAppState createState() => _SimpleAppState();
}

class _SimpleAppState extends State<SimpleApp> {
  int? _alarmSoundStreamId;
  int _cheeringStreamId = -1;

  String get _cheeringUrl => kIsWeb
      ? '/c-c-1.mp3'
      : 'https://raw.githubusercontent.com/ukasz123/soundpool/feature/web_support/example/web/c-c-1.mp3';

  Soundpool get _soundpool => widget.pool;

  void initState() {
    super.initState();

    _loadSounds();
  }

  void _loadSounds() {
    _soundId = _loadSound();
    _cheeringId = _loadCheering();
  }

  @override
  void didUpdateWidget(SimpleApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pool != widget.pool) {
      _loadSounds();
    }
  }

  double _volume = 1.0;
  double _rate = 1.0;
  late Future<int> _soundId;
  late Future<int> _cheeringId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                final newOptions = await Navigator.of(context).push<
                        SoundpoolOptions>(
                    MaterialPageRoute(builder: (context) => PlatformOptions()));
                if (newOptions != null) {
                  widget.onOptionsChange(newOptions);
                }
              },
              icon: Icon(
                Icons.access_alarms,
              ))
        ],
      ),
      body: Center(
        child: SizedBox(
          width: kIsWeb ? 450 : double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rolling dices'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                    onPressed: _playSound,
                    child: Text("Play"),
                  ),
                  SizedBox(width: 8),
                  RaisedButton(
                    onPressed: _pauseSound,
                    child: Text("Pause"),
                  ),
                  SizedBox(width: 8),
                  RaisedButton(
                    onPressed: _stopSound,
                    child: Text("Stop"),
                  ),
                ],
              ),
              SizedBox(height: 8),
              RaisedButton(
                onPressed: _playCheering,
                child: Text("Play cheering"),
              ),
              SizedBox(height: 4),
              Text('Set rate '),
              Row(children: [
                Expanded(
                  child: Slider.adaptive(
                    min: 0.5,
                    max: 2.0,
                    value: _rate,
                    onChanged: (newRate) {
                      setState(() {
                        _rate = newRate;
                      });
                      _updateCheeringRate();
                    },
                  ),
                ),
                Text('${_rate.toStringAsFixed(3)}'),
              ]),
              SizedBox(height: 8.0),
              Text('Volume'),
              Slider.adaptive(
                  value: _volume,
                  onChanged: (newVolume) {
                    setState(() {
                      _volume = newVolume;
                    });
                    _updateVolume(newVolume);
                  }),
            ],
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
    if (_alarmSoundStreamId != null) {
      await _soundpool.pause(_alarmSoundStreamId!);
    }
  }

  Future<void> _stopSound() async {
    if (_alarmSoundStreamId != null) {
      await _soundpool.stop(_alarmSoundStreamId!);
    }
  }

  Future<void> _playCheering() async {
    var _sound = await _cheeringId;
    _cheeringStreamId = await _soundpool.play(
      _sound,
      rate: _rate,
    );
  }

  Future<void> _updateCheeringRate() async {
    if (_cheeringStreamId > 0) {
      await _soundpool.setRate(
          streamId: _cheeringStreamId, playbackRate: _rate);
    }
  }

  Future<void> _updateVolume(newVolume) async {
    // if (_alarmSound >= 0){
    var _cheeringSound = await _cheeringId;
    _soundpool.setVolume(soundId: _cheeringSound, volume: newVolume);
    // }
  }
}
