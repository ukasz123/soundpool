import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class Soundpool {
  static const MethodChannel _channel =
      const MethodChannel('pl.ukaszapps/soundpool');

  static const _DEFAULT_SOUND_PRIORITY = 1;

  final int _maxStreams;
  final StreamType _streamType;
  final Completer<int> _soundpoolId = Completer();

  bool _disposed = false;

  Soundpool._([StreamType type = StreamType.music, int maxStreams = 1])
      : assert(type != null),
        _streamType = type,
        _maxStreams = maxStreams;

  /// Creates the Soundpool instance with stream type setting set.
  /// Soundpool can play up to [maxStreams] of simultaneous streams
  /// 
  /// *Note:* Optional [streamType] parameter has effect on Android only.
  factory Soundpool(
      {StreamType streamType = StreamType.music, int maxStreams = 1}) {
    return Soundpool._(streamType, maxStreams).._connect();
  }

  /// Prepares sound for playing
  ///
  /// ```
  /// load(await rootBundle.load("sounds/dices.m4a")); // loads file from assets
  /// ```
  ///
  /// Returns soundId for future use in [play] (soundId > -1)
  Future<int> load(ByteData rawSound,
          {int priority = _DEFAULT_SOUND_PRIORITY}) =>
      loadUint8List(rawSound.buffer.asUint8List(), priority: priority);

  /// Prepares sound for playing
  ///
  /// Loads sound data and buffers it for future playing.
  ///
  /// Returns soundId for future use in [play] (soundId > -1)
  Future<int> loadUint8List(Uint8List rawSound,
      {int priority = _DEFAULT_SOUND_PRIORITY}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    int soundId = await _channel.invokeMethod(
        "load", {"poolId": poolId, "rawSound": rawSound, "priority": priority});
    return soundId;
  }

  /// Prepares sound for playing
  ///
  /// Loads sound data from file pointed by [uri]
  /// Returns soundId for future use in [play] (soundId > -1)
  Future<int> loadUri(String uri,
      {int priority = _DEFAULT_SOUND_PRIORITY}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    int soundId = await _channel.invokeMethod(
        "loadUri", {"poolId": poolId, "uri": uri, "priority": priority});
    return soundId;
  }

  /// Prepares sound for playing and plays immediately when loaded
  ///
  /// ```
  /// loadAndPlay(await rootBundle.load("sounds/dices.m4a")); // loads file from assets
  /// ```
  ///
  /// Returns soundId for future use in [play] (soundId > -1)
  ///
  /// See also:
  ///
  /// * [load], which allows for precaching the sound data
  Future<int> loadAndPlay(ByteData rawSound,
      {int priority = _DEFAULT_SOUND_PRIORITY, int repeat = 0}) async {
    int soundId = await load(rawSound, priority: priority);
    play(soundId, repeat: repeat);
    return soundId;
  }

  /// Prepares sound for playing and plays immediately after loading
  ///
  /// Loads sound data, buffers it for future playing and starts playing immediately
  /// when loaded.
  ///
  /// Returns soundId for future use in [play] (soundId > -1)
  ///
  /// See also:
  ///
  /// * [loadUint8List], which allows for precaching the sound data
  Future<int> loadAndPlayUint8List(Uint8List rawSound,
      {int priority = _DEFAULT_SOUND_PRIORITY, int repeat = 0}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    int soundId = await _channel.invokeMethod(
        "load", {"poolId": poolId, "rawSound": rawSound, "priority": priority});
    play(soundId, repeat: repeat);
    return soundId;
  }

  /// Prepares sound for playing and plays immediately after loading
  ///
  /// Loads sound data from file pointed by [uri]
  ///
  /// Returns soundId for future use in [play] (soundId > -1)
  ///
  /// See also:
  ///
  /// * [loadUri], which allows for precaching the sound data
  Future<int> loadAndPlayUri(String uri,
      {int priority = _DEFAULT_SOUND_PRIORITY, int repeat = 0}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    int soundId = await _channel.invokeMethod(
        "loadUri", {"poolId": poolId, "uri": uri, "priority": priority});
    play(soundId, repeat: repeat);
    return soundId;
  }

  /// Plays sound identified by [soundId]
  ///
  /// Returns streamId to further control playback or 0 if playing failed to
  /// start
  Future<int> play(int soundId, {int repeat = 0}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    return await _channel.invokeMethod(
            "play", {"poolId": poolId, "soundId": soundId, "repeat": repeat})
        as int;
  }

  /// Starts playing the sound identified by [soundId].
  ///
  /// Returns instance to control playback
  Future<AudioStreamControl> playWithControls(int soundId,
      {int repeat = 0}) async {
    final streamId = await play(soundId, repeat: repeat);
    return AudioStreamControl._(this, streamId);
  }

  /// Stops playing sound identified by [streamId]
  ///
  ///
  Future<void> stop(int streamId) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    await _channel.invokeMethod("stop", {
      "poolId": poolId,
      "streamId": streamId,
    });
  }

  /// Pauses playing sound identified by [streamId]
  ///
  ///
  Future<void> pause(int streamId) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    await _channel.invokeMethod("pause", {
      "poolId": poolId,
      "streamId": streamId,
    });
  }

  /// Resumes playing sound identified by [streamId]
  ///
  ///
  Future<void> resume(int streamId) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    await _channel.invokeMethod("resume", {
      "poolId": poolId,
      "streamId": streamId,
    });
  }

  /// Sets volume for playing sound identified by [soundId] or [streamId]
  ///
  /// At least [volume] or both [volumeLeft] and [volumeRight] have to be passed
  Future setVolume(
      {int soundId,
      int streamId,
      double volume,
      double volumeLeft,
      double volumeRight}) {
    assert(!_disposed, "Soundpool instance was already disposed");
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
    return _soundpoolId.future
        .then((poolId) => _channel.invokeMethod("setVolume", {
              "poolId": poolId,
              "soundId": soundId,
              "streamId": streamId,
              "volumeLeft": volumeLeft,
              "volumeRight": volumeRight,
            }));
  }

  /// Releases loaded sounds
  ///
  /// Should be called to clear buffered sounds
  Future release() {
    assert(!_disposed, "Soundpool instance was already disposed");
    return _soundpoolId.future
        .then((poolId) => _channel.invokeMethod("release", {"poolId": poolId}));
  }

  /// Disposes soundpool
  ///
  /// The Soundpool instance is not usable anymore
  void dispose() {
    _soundpoolId.future.then(
        (poolId) => _channel.invokeMethod("dispose", {
              "poolId": poolId,
            }),
        onError: (_) {});
    _disposed = true;
  }

  StreamType get streamType => _streamType;

  /// Connects to native Soundpool instance
  _connect() async {
    final int id = await _channel.invokeMethod("initSoundpool",
        {"maxStreams": _maxStreams, "streamType": _streamType.index});
    if (id >= 0) {
      _soundpoolId.complete(id);
    } else {
      _soundpoolId.completeError("Soundpool initialization failed");
    }
  }
}

/// The type of the audio stream. Different streams may have distinct audio
/// settings (e.g. volume level) within the system
///
/// All sounds for particular Soundpool would be played using the selected stream
enum StreamType {
  /// Audio stream for the phone ring
  ring,

  /// Audio stream for alarms
  alarm,

  /// Audio stream for music playbacks
  music,

  /// Audio stream for notifications
  notification
}

/// Controls for played sound
///
/// Utility class that wraps the stream id with a easy-to-use API
class AudioStreamControl {
  final Soundpool _pool;
  bool _playing = true;
  bool _stopped = false;

  /// Id of the stream that is controlled by this object
  final int stream;

  /// Returns true if stream is not paused
  ///
  /// This does not reflect actual player state. The sound may have been finished
  /// any moment before by reaching the end
  bool get playing => _playing;

  /// Returns true if stream has been stopped and cannot be resumed
  ///
  /// This does not reflect actual player state. The sound may have been finished
  /// any moment before by reaching the end
  bool get stopped => _stopped;

  AudioStreamControl._(this._pool, this.stream);

  /// Stops playing the stream associated with this object
  Future<void> stop() async {
    await _pool.stop(stream);
    _stopped = true;
    _playing = false;
  }

  /// Pauses playing the stream associated with this object
  Future<void> pause() async {
    if (!_stopped && _playing) {
      await _pool.pause(stream);
      _playing = false;
    }
  }

  /// Resumes paused stream associated with this object
  Future<void> resume() async {
    if (!_stopped && _playing) {
      await _pool.pause(stream);
      _playing = true;
    }
  }

  /// Sets volume for playing sound identified by [soundId] or [streamId]
  ///
  /// At least [volume] or both [volumeLeft] and [volumeRight] have to be passed
  Future setVolume({double volume, double volumeLeft, double volumeRight}) {
    return _pool.setVolume(
        streamId: stream,
        volume: volume,
        volumeLeft: volumeLeft,
        volumeRight: volumeRight);
  }
}
