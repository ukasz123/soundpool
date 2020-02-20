import 'package:flutter/material.dart';

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Soundpool> soundpools = [];
  Map<Soundpool, SoundsMap> soundsMap;
  Soundpool _selectedPool;
  int _selectedIndex = 0;

  @override
  initState() {
    super.initState();
    initSoundPools();
  }

  @override
  Widget build(BuildContext context) {
    final ready = (soundpools.length > 0) && _selectedPool != null;
    final Widget body =
        ready ? _buildReadyWidget(context) : _buildWaitingWidget(context);
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Soundpool plugin example app'),
          actions: <Widget>[
            new IconButton(
              icon: Icon(Icons.clear_all),
              tooltip: "Releases all sounds",
              onPressed: () {
                resetSoundpool();
              },
            )
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
        body: body,
        floatingActionButton: ready
            ? new FloatingActionButton(
                onPressed: soundsMap[_selectedPool].playing
                    ? pauseStream
                    : soundsMap[_selectedPool].dicesSoundId != null &&
                            soundsMap[_selectedPool].dicesSoundId >= 0
                        ? playSound
                        : null,
                child: new Icon(soundsMap[_selectedPool].playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled),
              )
            : null,
      ),
    );
  }

  Stack _buildReadyWidget(BuildContext context) {
    return new Stack(
      children: <Widget>[
        Positioned(
          top: 8.0,
          child: Text(_selectedPool.streamType.toString()),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: new Text('Volume control'),
            ),
            new Slider(
                value: soundsMap[_selectedPool].volume,
                onChanged: (newValue) {
                  setState(() {
                    soundsMap[_selectedPool].volume = newValue;
                    updateVolume();
                  });
                }),
          ],
        ),
        new Positioned(
            bottom: 16.0,
            left: 16.0,
            child: new FloatingActionButton(
              onPressed: soundsMap[_selectedPool].dicesSoundFromUriId == null ||
                      soundsMap[_selectedPool].dicesSoundFromUriId < 0
                  ? null
                  : () => playSoundFromUri(),
              child: new Icon(Icons.play_arrow),
            ))
      ],
    );
  }

  void initSoundPools() {
    soundpools =
        StreamType.values.map((type) => Soundpool(streamType: type)).toList();

    soundsMap = Map.fromEntries(
        soundpools.map((soundpool) => MapEntry(soundpool, SoundsMap())));
    print("Waiting for all pools to initialize themself");
    Future.wait(
            soundpools.map((pool) => initSoundsForPool(pool, soundsMap[pool])))
        .then((_) {
      setState(() {
        _selectedPool = soundpools[_selectedIndex];
      });
    });
  }

  Future<void> playSound() async {
    if (soundsMap[_selectedPool].dicesSoundId > -1) {
      if (soundsMap[_selectedPool].dicesStreamId != null) {
        await _selectedPool.resume(soundsMap[_selectedPool].dicesStreamId);

        soundsMap[_selectedPool].dicesStreamId = null; /**/
      } else {
        int streamId = soundsMap[_selectedPool].dicesStreamId =
            await _selectedPool.play(soundsMap[_selectedPool].dicesSoundId,
                repeat: 4);
        soundsMap[_selectedPool].playing = true;
        print("Playing sound with stream id: $streamId");
      }
    }
    setState(() {});
  }

  Future<void> pauseStream() async {
    if (soundsMap[_selectedPool].dicesStreamId != null) {
      await _selectedPool.pause(soundsMap[_selectedPool].dicesStreamId);
      setState(() {
        soundsMap[_selectedPool].playing = false;
      });
    }
  }

  void updateVolume() {
    if (soundsMap[_selectedPool].dicesStreamId != null) {
      _selectedPool.setVolume(
          streamId: soundsMap[_selectedPool].dicesStreamId,
          soundId: soundsMap[_selectedPool].dicesSoundId,
          volume: soundsMap[_selectedPool].volume);
    } else {
      _selectedPool.setVolume(
          soundId: soundsMap[_selectedPool].dicesSoundId,
          volume: soundsMap[_selectedPool].volume);
    }
  }

  void playSoundFromUri() {
    _selectedPool.play(soundsMap[_selectedPool].dicesSoundFromUriId);
  }

  void resetSoundpool() async {
    setState(() {
      soundsMap[_selectedPool].dicesSoundId = -1;
      soundsMap[_selectedPool].dicesSoundFromUriId = -1;
    });
    _selectedPool.dispose();
    initSoundsForPool(_selectedPool, soundsMap[_selectedPool]).then((_) {
      setState(() {});
    });
  }

  _buildBottomNavigationBar(BuildContext context) {
    if (soundpools.length > 1) {
      return BottomNavigationBar(
        items: soundpools
            .map((s) => s.streamType)
            .map((streamType) => BottomNavigationBarItem(
                backgroundColor: Colors.lightBlueAccent,
                icon: Icon(Icons.pages),
                title: Text(streamType.toString())))
            .toList(),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _selectedPool = soundpools[_selectedIndex];
          });
        },
      );
    } else {
      return new Container(
        height: 40.0,
        child: Center(
          child: Text("Loading soundpools"),
        ),
      );
    }
  }

  Widget _buildWaitingWidget(BuildContext context) {
    return Center(child: CircularProgressIndicator());
  }

  Future<Null> initSoundsForPool(Soundpool pool, SoundsMap sounds) async {
    print("Loading sounds for pool ${pool.streamType}...");
    sounds.dicesSoundId =
        await rootBundle.load("sounds/do-you-like-it.wav").then((ByteData soundData) {
      return pool.load(soundData);
      
    });
    await pool.setVolume(soundId: sounds.dicesSoundId, volume: sounds.volume);
    sounds.dicesSoundFromUriId = await pool.loadUri(
        "https://github.com/ukasz123/soundpool/raw/master/example/sounds/dices.m4a");
    print(
        "stream = ${pool.streamType}: dicesSoundId = ${sounds.dicesSoundId}, dicesSoundFromUri = ${sounds.dicesSoundFromUriId}");
    return;
  }
}

class SoundsMap {
  int dicesSoundId;

  int dicesStreamId;

  int dicesSoundFromUriId;

  double volume = 1.0;

  bool playing = false;
}
