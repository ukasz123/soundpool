import 'package:flutter/material.dart';
import 'package:soundpool_example/benchmarking.dart';
import 'package:soundpool_example/initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      home: SoundpoolInitializer(
        builder: (context, pool, reinitializePool) =>
            BenchmarkingApp(pool: pool),
      ),
    ),
  );
}
