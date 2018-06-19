import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class Soundpool {
  static const MethodChannel _channel =
      const MethodChannel('pl.ukaszapps/soundpool');

  static const _DEFAULT_SOUND_PRIORITY = 1;

  /// Prepares sound for playing
  ///
  /// Soundpool.load(await rootBundle.load("sounds/dices.m4a")); // loads file
  /// from assets
  ///
  /// Returns soundId for future use in [play]
  static Future<int> load(ByteData rawSound,
          {int priority = _DEFAULT_SOUND_PRIORITY}) =>
      loadUint8List(rawSound.buffer.asUint8List(), priority: priority);

  /// Prepares sound for playing
  ///
  /// Loads sound data and buffers it for future playing.
  /// Returns soundId for future use in [play]
  static Future<int> loadUint8List(Uint8List rawSound,
      {int priority = _DEFAULT_SOUND_PRIORITY}) async {
    int soundId = await _channel
        .invokeMethod("load", {"rawSound": rawSound, "priority": priority});
    return soundId;
  }

  /// Prepares sound for playing
  ///
  /// Loads sound data from file pointed by [uri]
  /// Returns soundId for future use in [play]
  static Future<int> loadUri(String uri,
      {int priority = _DEFAULT_SOUND_PRIORITY}) async {
    int soundId = await _channel
        .invokeMethod("loadUri", {"uri": uri, "priority": priority});
    return soundId;
  }

  /// Plays sound identified by [soundId]
  ///
  /// Returns streamId to further control playback or 0 if playing failed to
  /// start
  static Future<int> play(int soundId, {int repeat = 0}) async => await _channel
      .invokeMethod("play", {"soundId": soundId, "repeat": repeat}) as int;

  /// Sets volume for playing sound identified by [soundId] or [streamId]
  ///
  ///
  static Future setVolume(
      {int soundId,
      int streamId,
      double volume,
      double volumeLeft,
      double volumeRight}) {
    assert(
        soundId != null || streamId != null,
        "Either 'soundId' or 'streamI"
        "d' has to be passed");
    assert(
        volume != null || (volumeLeft != null && volumeRight != null),
        "Ei"
        "ther 'volume' or both 'volumeLeft' and 'volumeRight' has to be "
        "passed");

    if (volume != null && volumeLeft == null) {
      volumeLeft = volume;
    }
    if (volume != null && volumeRight == null) {
      volumeRight = volume;
    }
    return _channel.invokeMethod("setVolume", {
      "soundId": soundId,
      "streamId": streamId,
      "volumeLeft": volumeLeft,
      "volumeRight": volumeRight,
    });
  }

  /// Releases loaded sounds
  ///
  /// Should be called to clear buffered sounds
  static Future release() => _channel.invokeMethod("release");
}
