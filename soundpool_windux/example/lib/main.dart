import 'dart:math';

import 'package:flutter/material.dart';
import 'package:soundpool_windux/soundpool_windux.dart';

void main() {
  SoundpoolPlatformSetup.prepare(forceMacosFFI: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  late SoundpoolWindux soundpool;

  int? _poolId;

  List<int> _soundIds = [];

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    super.initState();
    this.soundpool = SoundpoolWindux();
  }

  @override
  void dispose() {
    if (_poolId != null) {
      soundpool.dispose(_poolId!);
    }
    super.dispose();
  }

  Future<void> showErrorDialog(Object error, dynamic stacktrace) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text('$error'),
          content: Text('$stacktrace'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
                onPressed: () {
                  soundpool.init(0, 0, {}).then(
                    (id) => setState(() => _poolId = id),
                    onError: showErrorDialog,
                  );
                },
                child: Text('Initialize')),
            Text('poolId = $_poolId'),
            SizedBox(height: 12),
            ElevatedButton(
                onPressed: _poolId != null
                    ? () async {
                        var bufferedSoundId = await soundpool.loadUri(
                            _poolId!,
                            Random().nextBool()
                                ? 'https://github.com/ukasz123/soundpool/blob/master/soundpool/example/sounds/do-you-like-it.wav?raw=true'
                                : 'https://www.bensound.com/bensound-music/bensound-clearday.mp3',
                            0);
                        print('Buffered = $bufferedSoundId');
                        setState(() => _soundIds.add(bufferedSoundId));
                      }
                    : null,
                child: Text('Load from web')),
            LimitedBox(
              maxHeight: 64.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _soundIds
                    .map(
                      (soundId) => ElevatedButton.icon(
                        onPressed: () async {
                          var streamId =
                              await soundpool.play(_poolId!, soundId, 0, 1);
                          print('stream => $streamId');
                        },
                        label: Text('Play'),
                        icon: Icon(Icons.play_arrow),
                      ),
                    )
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: e,
                        ))
                    .toList(),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
