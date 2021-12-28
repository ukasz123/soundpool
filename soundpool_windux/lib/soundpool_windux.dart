/// @nodoc
library soundpool_windux;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:soundpool_platform_interface/soundpool_platform_interface.dart';
import 'package:soundpool_windux/generated_bindings.dart';

class SoundpoolPlatformSetup {
  static void prepare({bool forceMacosFFI = false}) {
    if (Platform.isWindows || Platform.isLinux) {
      SoundpoolPlatform.instance = SoundpoolWindux();
    }
    if (forceMacosFFI && Platform.isMacOS) {
      SoundpoolPlatform.instance = SoundpoolWindux();
    }
    // ignore platforms supporting curated plugins
  }
}

/// @nodoc

class SoundpoolWindux extends SoundpoolPlatform {
  int lastPoolId = -1;

  final Map<int, _AudioPool> _poolCache = {};

  static void registerWith() {
    SoundpoolPlatformSetup.prepare();
  }

  @override
  Future<int> init(int streamType, int maxStreams,
      Map<String, dynamic> plaformOptions) async {
    final poolId = ++lastPoolId;
    _poolCache[poolId] = _AudioPool(poolId);
    return poolId;
  }

  @override
  Future<int> loadUint8List(int poolId, Uint8List rawSound, int priority) {
    var pool = _poolCache[poolId];
    return pool!.load(rawSound);
  }

  @override
  Future<int> loadUri(int poolId, String uri, int priority) async {
    var response = await http.get(Uri.parse(uri));
    return await loadUint8List(poolId, response.bodyBytes, priority);
  }

  @override
  Future<void> dispose(int poolId) async {
    final pool = _poolCache.remove(poolId);
    pool?.dispose();
  }

  @override
  Future<void> release(int poolId) {
    throw UnimplementedError('release() has not been implemented');
  }

  @override
  Future<int> play(int poolId, int soundId, int repeat, double rate) {
    return _poolCache[poolId]!.play(soundId, repeat, rate);
  }

  @override
  Future<void> stop(int poolId, int streamId) {
    return _poolCache[poolId]!.stop(streamId);
  }

  @override
  Future<void> pause(int poolId, int streamId) {
    throw UnimplementedError('pause() has not been implemented');
  }

  @override
  Future<void> resume(int poolId, int streamId) {
    throw UnimplementedError('resume() has not been implemented');
  }

  @override
  Future<void> setVolume(int poolId, int? soundId, int? streamId,
      double? volumeLeft, double? volumeRight) {
    throw UnimplementedError('setVolume() has not been implemented');
  }

  @override
  Future<void> setRate(int poolId, int streamId, double? playbackRate) {
    throw UnimplementedError('setRate() has not been implemented');
  }
}

class _AudioPool {
  final int poolId;
  final ffi.Pointer<ffi.Void> poolPointer;

  _AudioPool(this.poolId) : poolPointer = poolConnector.create_pool();

  void dispose() {
    poolConnector.destroy_pool(poolPointer);
  }

  Future<int> load(Uint8List rawSound) {
    return Future(() {
      var outBuf = malloc.allocate<ffi.Uint8>(rawSound.length);
      for (int index = 0; index < rawSound.length; index++) {
        outBuf[index] = rawSound[index];
      }
      var soundId =
          poolConnector.load_buffer(poolPointer, outBuf, rawSound.length);
      malloc.free(outBuf);
      return soundId;
    });
  }

  Future<int> play(int soundId, int repeat, double rate) {
    return Future(() => poolConnector.play(poolPointer, soundId, repeat, rate));
  }

  Future<void> stop(int streamId) async {
    poolConnector.stop(poolPointer, streamId);
  }
}

late final RustSoundpool _rustSoundpool = _ffiConnect();

RustSoundpool get poolConnector => _rustSoundpool;

RustSoundpool _ffiConnect() {
  var libraryPath = 'libsoundpool.so';
  if (Platform.isMacOS) {
    libraryPath = 'libsoundpool.dylib';
  } else if (Platform.isWindows) {
    libraryPath = 'soundpool.dll';
  }
  ffi.DynamicLibrary dynamicLibrary = ffi.DynamicLibrary.open(libraryPath);
  return RustSoundpool(dynamicLibrary);
}

extension _CacheExt<T> on Map<int, T> {
  int get nextKey => isEmpty
      ? 0
      : keys.reduce((left, right) => left > right ? left : right) + 1;
}
