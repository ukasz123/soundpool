import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int dicesSoundId;

  int dicesStreamId;

  double volume = 1.0;

  @override
  initState() {
    super.initState();
    initSoundPool();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Soundpool plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: new Text('Volume control'),
            ),
            new Slider(
                value: volume,
                onChanged: (newValue) {
                  setState(() {
                    volume = newValue;
                    updateVolume();
                  });
                }),
          ],
        ),
        floatingActionButton: new FloatingActionButton(
            onPressed: () => playSound(),
            child: new Icon(Icons.play_circle_filled)),
      ),
    );
  }

  void initSoundPool() async {
    dicesSoundId =
        await rootBundle.load("sounds/dices.m4a").then((ByteData soundData) {
      return Soundpool.load(soundData);
    });
    await Soundpool.setVolume(soundId: dicesSoundId, volume: volume);
  }

  void playSound() async {
    if (dicesSoundId > -1) {
      dicesStreamId = await Soundpool.play(dicesSoundId, repeat: 4);
    }
  }

  void updateVolume() {
    if (dicesStreamId != null) {
      Soundpool.setVolume(
          streamId: dicesStreamId, soundId: dicesSoundId, volume: volume);
    } else {
      Soundpool.setVolume(soundId: dicesSoundId, volume: volume);
    }
  }
}
