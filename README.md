# soundpool

A Flutter Sound Pool for playing short media files.

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