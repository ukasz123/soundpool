# soundpool

A Flutter Sound Pool for playing short media files.

**Sound Pool caches audio tracks in memory.**
This can be useful in following scenarios:
- lower latency between play signal and actual playing of the sound (audio does not need to be read from disc/web),
- the same sound may be used multiple times.

Inspired by [Android SoundPool API](https://developer.android.com/reference/android/media/SoundPool).

Example:

```dart
    import 'package:soundpool/soundpool.dart';

    Soundpool pool = Soundpool(streamType: StreamType.notification);

    int soundId = await rootBundle.load("sounds/dices.m4a").then((ByteData soundData) {
                  return pool.load(soundData);
                });
    int streamId = await pool.play(soundId);
```