import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:soundpool/soundpool.dart';

typedef SoundpoolReadyWidgetBuilder = Widget Function(BuildContext context,
    Soundpool pool, void Function(SoundpoolOptions) reinitializePool);

class SoundpoolInitializer extends StatefulWidget {
  final SoundpoolReadyWidgetBuilder builder;

  const SoundpoolInitializer({Key? key, required this.builder})
      : super(key: key);
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
          child: ElevatedButton(
            onPressed: () => _initPool(_soundpoolOptions),
            child: Text("Init Soundpool"),
          ),
        ),
      );
    } else {
      return widget.builder(context, _pool!, _initPool);
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
