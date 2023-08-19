import 'dart:async';
import 'dart:typed_data';

import 'package:soundpool_platform_interface/soundpool_platform_interface.dart';

import 'src/platform_options.dart';

export 'src/platform_options.dart';

class Soundpool {
  static const _DEFAULT_SOUND_PRIORITY = 1;

  final int _maxStreams;
  final StreamType _streamType;
  final Map<String, dynamic> _platformOptions;
  final Completer<int> _soundpoolId = Completer();

  SoundpoolPlatform get _platformInstance => SoundpoolPlatform.instance;

  bool _disposed = false;

  Soundpool._(this._platformOptions,
      [StreamType type = StreamType.music, int maxStreams = 1])
      : assert(maxStreams > 0),
        _streamType = type,
        _maxStreams = maxStreams;

  @override
  String toString() {
    return 'Soundpool($_streamType:$hashCode)';
  }

  /// Creates the Soundpool instance with stream type setting set.
  /// Soundpool can play up to [maxStreams] of simultaneous streams
  ///
  /// *Note:* Optional [streamType] parameter has effect on Android only.
  @Deprecated('Use `fromOptions` instead')
  factory Soundpool(
          {StreamType streamType = StreamType.music, int maxStreams = 1}) =>
      Soundpool.fromOptions(
        options: SoundpoolOptions(
          streamType: streamType,
          maxStreams: maxStreams,
        ),
      );

  /// Creates the Soundpool instance with stream type setting set.
  factory Soundpool.fromOptions(
      {SoundpoolOptions options = SoundpoolOptions.kDefault}) {
    return Soundpool._(
      options._platformOptions,
      options.streamType,
      options.maxStreams,
    ).._connect();
  }

  /// Prepares sound for playing
  ///
  /// ```
  /// load(await rootBundle.load("sounds/dices.m4a")); // loads file from assets
  /// ```
  ///
  /// Returns soundId for future use in [play] (soundId > -1) or `-1` when sound file failed to load
  ///
  /// ## web
  /// [priority] is ignored.
  Future<int> load(ByteData rawSound,
          {int priority = _DEFAULT_SOUND_PRIORITY}) =>
      loadUint8List(rawSound.buffer.asUint8List(), priority: priority);

  /// Prepares sound for playing
  ///
  /// Loads sound data and buffers it for future playing.
  ///
  /// Returns soundId for future use in [play] (soundId > -1) or `-1` when sound data failed to load
  ///
  /// ## web
  /// [priority] is ignored.
  Future<int> loadUint8List(Uint8List rawSound,
      {int priority = _DEFAULT_SOUND_PRIORITY}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    int soundId =
        await _platformInstance.loadUint8List(poolId, rawSound, priority);
    return soundId;
  }

  /// Prepares sound for playing
  ///
  /// Loads sound data from file pointed by [uri]
  /// Returns soundId for future use in [play] (soundId > -1) or `-1` when sound file failed to load
  ///
  /// ## web
  /// [priority] is ignored.
  Future<int> loadUri(String uri,
      {int priority = _DEFAULT_SOUND_PRIORITY}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int poolId = await _soundpoolId.future;
    int soundId = await _platformInstance.loadUri(poolId, uri, priority);
    return soundId;
  }

  /// Prepares sound for playing and plays immediately when loaded
  ///
  /// ```
  /// loadAndPlay(await rootBundle.load("sounds/dices.m4a")); // loads file from assets
  /// ```
  ///
  /// Returns soundId for future use in [play] (soundId > -1) or `-1` when sound file failed to load
  ///
  /// See also:
  ///
  /// * [load], which allows for precaching the sound data
  ///
  /// ## web
  /// [priority] and [repeat] are ignored. The sound is played only once.
  Future<int> loadAndPlay(ByteData rawSound,
      {int priority = _DEFAULT_SOUND_PRIORITY,
      int repeat = 0,
      double rate = 1.0}) async {
    int soundId = await load(rawSound, priority: priority);
    if (soundId > -1) {
      play(soundId, repeat: repeat, rate: rate);
    }
    return soundId;
  }

  /// Prepares sound for playing and plays immediately after loading
  ///
  /// Loads sound data, buffers it for future playing and starts playing immediately
  /// when loaded.
  ///
  /// Returns soundId for future use in [play] (soundId > -1) or `-1` when sound file failed to load
  ///
  /// See also:
  ///
  /// * [loadUint8List], which allows for precaching the sound data
  ///
  /// ## web
  /// [priority] and [repeat] are ignored. The sound is played only once.
  Future<int> loadAndPlayUint8List(Uint8List rawSound,
      {int priority = _DEFAULT_SOUND_PRIORITY,
      int repeat = 0,
      double rate = 1.0}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int soundId = await loadUint8List(rawSound, priority: priority);
    if (soundId > -1) {
      play(soundId, repeat: repeat, rate: rate);
    }
    return soundId;
  }

  /// Prepares sound for playing and plays immediately after loading
  ///
  /// Loads sound data from file pointed by [uri]
  ///
  /// Returns soundId for future use in [play] (soundId > -1) or `-1` when sound file failed to load
  ///
  /// See also:
  ///
  /// * [loadUri], which allows for precaching the sound data
  ///
  /// ## web
  /// [priority] and [repeat] are ignored. The sound is played only once.
  Future<int> loadAndPlayUri(String uri,
      {int priority = _DEFAULT_SOUND_PRIORITY,
      int repeat = 0,
      double rate = 1.0}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    int soundId = await loadUri(uri, priority: priority);
    if (soundId > -1) {
      play(soundId, repeat: repeat, rate: rate);
    }
    return soundId;
  }

  /// Plays sound identified by [soundId]
  ///
  /// Returns streamId to further control playback or 0 if playing failed to
  /// start
  ///
  /// ## web
  /// [repeat] is ignored. The sound is played only once.
  Future<int> play(int soundId, {int repeat = 0, double rate = 1.0}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    assert(
      rate >= 0.5 && rate <= 2.0,
      "'rate' has to be value in (0.5 - 2.0) range",
    );
    assert(soundId > -1,
        "Invalid 'soundId' parameter. Only values greater than -1 are valid.");
    int poolId = await _soundpoolId.future;
    return await _platformInstance.play(poolId, soundId, repeat, rate);
  }

  /// Starts playing the sound identified by [soundId].
  ///
  /// Returns instance to control playback
  ///
  /// ## web
  /// [repeat] is ignored. The sound is played only once.
  Future<AudioStreamControl> playWithControls(int soundId,
      {int repeat = 0, double rate = 1.0}) async {
    final streamId = await play(soundId, repeat: repeat, rate: rate);
    return AudioStreamControl._(this, streamId);
  }

  /// Stops playing sound identified by [streamId]
  ///
  ///
  Future<void> stop(int streamId) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    assert(streamId > 0,
        "Invalid 'streamId' parameter. Only values greater than 0 are valid.");
    int poolId = await _soundpoolId.future;
    await _platformInstance.stop(poolId, streamId);
  }

  /// Pauses playing sound identified by [streamId]
  ///
  /// ## web
  /// *DOES NOT WORK!*.
  Future<void> pause(int streamId) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    assert(streamId > 0,
        "Invalid 'streamId' parameter. Only values greater than 0 are valid.");
    int poolId = await _soundpoolId.future;
    await _platformInstance.pause(poolId, streamId);
  }

  /// Resumes playing sound identified by [streamId]
  ///
  /// ## web
  /// *DOES NOT WORK!*.
  Future<void> resume(int streamId) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    assert(streamId > 0,
        "Invalid 'streamId' parameter. Only values greater than 0 are valid.");
    int poolId = await _soundpoolId.future;
    await _platformInstance.resume(poolId, streamId);
  }

  /// Sets volume for playing sound identified by [soundId] or [streamId]
  ///
  /// At least [volume] or both [volumeLeft] and [volumeRight] have to be passed
  ///
  /// ## web
  /// [volumeLeft] and [volumeRight] pair has no effect.
  Future<void> setVolume(
      {int? soundId,
      int? streamId,
      double? volume,
      double? volumeLeft,
      double? volumeRight}) async {
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

    assert(streamId == null || streamId > 0,
        "Invalid 'streamId' parameter. Only values greater than 0 are valid.");
    assert(soundId == null || soundId > -1,
        "Invalid 'soundId' parameter. Only values greater than -1 are valid.");

    if (volume != null && volumeLeft == null) {
      volumeLeft = volume;
    }
    if (volume != null && volumeRight == null) {
      volumeRight = volume;
    }
    await _soundpoolId.future.then((poolId) => _platformInstance.setVolume(
        poolId, soundId, streamId, volumeLeft, volumeRight));
  }

  /// Sets playback rate. A value of 1.0 means normal speed, 0.5 - half speed, 2.0 - double speed.
  ///
  /// Available value range: (0.5 - 2.0)
  Future<void> setRate(
      {required int streamId, required double playbackRate}) async {
    assert(!_disposed, "Soundpool instance was already disposed");
    assert(streamId > 0,
        "Invalid 'streamId' parameter. Only values greater than 0 are valid.");
    assert(
      playbackRate >= 0.5 && playbackRate <= 2.0,
      "'playbackRate' has to be value in (0.5 - 2.0) range",
    );
    await _soundpoolId.future.then(
        (poolId) => _platformInstance.setRate(poolId, streamId, playbackRate));
  }

  /// Releases loaded sounds
  ///
  /// Should be called to clear buffered sounds
  Future<void> release() async {
    assert(!_disposed, "Soundpool instance was already disposed");
    await _soundpoolId.future
        .then((poolId) => _platformInstance.release(poolId));
  }

  /// Disposes soundpool
  ///
  /// The Soundpool instance is not usable anymore
  void dispose() {
    _disposed = true;
    unawaited(_soundpoolId.future
        .then((poolId) => _platformInstance.dispose(poolId), onError: (_) {}));
  }

  StreamType get streamType => _streamType;

  /// Connects to native Soundpool instance
  _connect() async {
    final int id = await _platformInstance.init(
        _streamType.index, _maxStreams, _platformOptions);
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
  Future setVolume({double? volume, double? volumeLeft, double? volumeRight}) {
    return _pool.setVolume(
        streamId: stream,
        volume: volume,
        volumeLeft: volumeLeft,
        volumeRight: volumeRight);
  }

  /// Sets playback rate. A value of 1.0 means normal speed, 0.5 - half speed, 2.0 - double speed.
  ///
  /// Available value range: (0.5 - 2.0)
  Future setRate({required double playbackRate}) {
    return _pool.setRate(
      streamId: stream,
      playbackRate: playbackRate,
    );
  }
}

class SoundpoolOptions {
  /// The type of stream used by the pool
  final StreamType streamType;

  /// Maximum number of pararell sounds being played
  final int maxStreams;

  /// Android specific options
  final SoundpoolOptionsAndroid androidOptions;

  /// iOS specific options
  final SoundpoolOptionsIos iosOptions;

  /// Web specific options
  final SoundpoolOptionsWeb webOptions;

  /// MacOS specific options
  final SoundpoolOptionsMacos macosOptions;

  const SoundpoolOptions({
    this.streamType = StreamType.music,
    this.maxStreams = 1,
    this.androidOptions = SoundpoolOptionsAndroid.kDefault,
    this.iosOptions = SoundpoolOptionsIos.kDefault,
    this.webOptions = SoundpoolOptionsWeb.kDefault,
    this.macosOptions = SoundpoolOptionsMacos.kDefault,
  });

  static const kDefault = SoundpoolOptions();

  Map<String, dynamic> get _platformOptions => Map.fromEntries([
        ...androidOptions
            .toOptionsMap()
            .entries
            .map((e) => MapEntry('android_${e.key}', e.value)),
        ...iosOptions
            .toOptionsMap()
            .entries
            .map((e) => MapEntry('ios_${e.key}', e.value)),
        ...webOptions
            .toOptionsMap()
            .entries
            .map((e) => MapEntry('web_${e.key}', e.value)),
        ...macosOptions
            .toOptionsMap()
            .entries
            .map((e) => MapEntry('macos_${e.key}', e.value)),
      ]);
}
