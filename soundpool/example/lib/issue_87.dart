import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class Issue87DemoPage extends StatelessWidget {
  const Issue87DemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BreatheBar(),
      ),
    );
  }
}

class BreatheBar extends StatefulWidget {
  const BreatheBar({Key? key}) : super(key: key);

  @override
  _BreathBarState createState() => _BreathBarState();
}

class _BreathBarState extends State<BreatheBar> with WidgetsBindingObserver {
  Timer? backgroundTimer;
  late Map<String, Map<String, int>> soundIds;
  Soundpool pool = Soundpool.fromOptions(
      options: const SoundpoolOptions(
          streamType: StreamType.alarm,
          iosOptions: SoundpoolOptionsIos(
              audioSessionCategory: AudioSessionCategory.playback)));

  void waitingPlaySound() {
    backgroundTimer = Timer(const Duration(seconds: 5), () {
      playSound(pool, soundIds);
      waitingPlaySound();
    });
  }

  @override
  void initState() {
    loadSounds(pool).then((Map<String, Map<String, int>> codes) {
      soundIds = codes;
    }).then((_) {
      waitingPlaySound();
    });
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("didChangeAppLifecycleState: $state");
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(30),
        child: const Text("Playing a sound every 5 seconds"));
  }
}

Map<String, Map<String, String>> sounds = {
  'Notify': {'inhale': 'sounds/inhale.mp3', 'exhale': 'sounds/exhale.mp3'}
};

Future<Map<String, Map<String, int>>> loadSounds(Soundpool pool) async {
  Map<String, Map<String, int>> loadedSounds = {};
  sounds.forEach((key, value) async {
    int inId =
        await rootBundle.load(value['inhale']!).then((ByteData soundData) {
      return pool.load(soundData);
    });
    int outId =
        await rootBundle.load(value['exhale']!).then((ByteData soundData) {
      return pool.load(soundData);
    });
    loadedSounds[key] = {'inhale': inId, 'exhale': outId};
  });
  return loadedSounds;
}

void playSound(Soundpool pool, Map<String, Map<String, int>> loaded) {
  int id = loaded['Notify']!['inhale']!;
  print('play sound $id at ${DateTime.now().second}');
  pool.play(id);
}
