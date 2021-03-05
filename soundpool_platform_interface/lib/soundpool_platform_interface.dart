import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_soundpool_platform.dart';

/// The interface that implementations of soundpool must implement.
///
/// This class creates [SoundpoolPlatformInterface] instances to do the actual communication with
/// platform specific code.
abstract class SoundpoolPlatform extends PlatformInterface {
  SoundpoolPlatform() : super(token: _token);

  static final Object _token = Object();

  static SoundpoolPlatform _instance = MethodChannelSoundpoolPlatform();

  static SoundpoolPlatform get instance => _instance;

  static set instance(SoundpoolPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes Soundpool
  ///
  /// Completes with value >=0 if operation was successful
  Future<int> init(int streamType, int maxStreams) {
    throw UnimplementedError('createSoundpool() has not been implemented');
  }

  Future<int> loadUint8List(int poolId, Uint8List rawSound, int priority) {
    throw UnimplementedError('loadUint8List() has not been implemented');
  }

  Future<int> loadUri(int poolId, String uri, int priority) {
    throw UnimplementedError('loadUri() has not been implemented');
  }

  Future<void> dispose(int poolId) {
    throw UnimplementedError('dispose() has not been implemented');
  }

  Future<void> release(int poolId) {
    throw UnimplementedError('release() has not been implemented');
  }

  Future<int> play(int poolId, int soundId, int repeat, double rate) {
    throw UnimplementedError('play() has not been implemented');
  }

  Future<void> stop(int poolId, int streamId) {
    throw UnimplementedError('stop() has not been implemented');
  }

  Future<void> pause(int poolId, int streamId) {
    throw UnimplementedError('pause() has not been implemented');
  }

  Future<void> resume(int poolId, int streamId) {
    throw UnimplementedError('resume() has not been implemented');
  }

  Future<void> setVolume(int poolId, int? soundId, int? streamId,
      double? volumeLeft, double? volumeRight) {
    throw UnimplementedError('setVolume() has not been implemented');
  }

  Future<void> setRate(int poolId, int streamId, double playbackRate) {
    throw UnimplementedError('setRate() has not been implemented');
  }
}
