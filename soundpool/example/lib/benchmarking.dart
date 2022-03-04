import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

const _kDrumAssetPath = 'sounds/bad-drum-punchy-snare.wav';

class BenchmarkingApp extends StatelessWidget {
  final Soundpool pool;

  const BenchmarkingApp({Key? key, required this.pool}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Benchmarking')),
      body: FutureBuilder<int>(
          future: rootBundle.load(_kDrumAssetPath).then((value) async {
            return pool.load(value);
          }),
          builder: ((context, snapshot) {
            if (snapshot.hasData) {
              return BenchmarkingView(pool: pool, soundId: snapshot.data!);
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            return Center(
              child: CircularProgressIndicator(),
            );
          })),
    );
  }
}

class BenchmarkingView extends StatefulWidget {
  const BenchmarkingView({Key? key, required this.pool, required this.soundId})
      : super(key: key);

  final Soundpool pool;
  final int soundId;

  @override
  State<BenchmarkingView> createState() => _BenchmarkingViewState();
}

enum _IndicatorState { idle, playing }

class _BenchmarkingViewState extends State<BenchmarkingView> {
  var _state = _IndicatorState.idle;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: SizedBox.square(
              dimension: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _state == _IndicatorState.idle
                      ? Colors.grey
                      : Colors.deepOrangeAccent,
                  shape: BoxShape.circle,
                  border: Border.all(),
                ),
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTapDown: _state == _IndicatorState.idle
                  ? (_) => _triggerPlaying()
                  : null,
              child: Container(
                padding: const EdgeInsets.all(32.0),
                color: Colors.lightGreen.shade200,
                child: Text('Play'),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _triggerPlaying() {
    setState(() {
      _state = _IndicatorState.playing;
    });
    print(
        '${DateTime.now().millisecondsSinceEpoch} - BENCHMARKING: start playing - before play');
    widget.pool.play(widget.soundId);
    print(
        '${DateTime.now().millisecondsSinceEpoch} - BENCHMARKING: start playing  - before play');
    _timer = Timer(
      Duration(milliseconds: 600),
      () => setState(() {
        _state = _IndicatorState.idle;
      }),
    );
  }
}
