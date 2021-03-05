import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:soundpool_platform_interface/soundpool_platform_interface.dart';

class MethodChannelSoundpoolPlatform extends SoundpoolPlatform {
  static const MethodChannel _channel =
      const MethodChannel('pl.ukaszapps/soundpool');

  @override
  Future<int> init(int streamType, int maxStreams) => _channel.invokeMethod<int>(
      "initSoundpool", {"maxStreams": maxStreams, "streamType": streamType}).then((value) => value!);

  @override
  Future<int> loadUri(int poolId, String uri, int priority) =>
      _channel.invokeMethod<int>(
          "loadUri", {"poolId": poolId, "uri": uri, "priority": priority}).then((value) => value!);

  @override
  Future<int> loadUint8List(int poolId, Uint8List rawSound, int priority) =>
      _channel.invokeMethod<int>("load",
          {"poolId": poolId, "rawSound": rawSound, "priority": priority}).then((value) => value!);

  @override
  Future<int> play(int poolId, int soundId, int repeat, double rate) async =>
      (await _channel.invokeMethod<int>("play", {
        "poolId": poolId,
        "soundId": soundId,
        "repeat": repeat,
        "rate": rate
      })) as int;

  @override
  Future<void> stop(int poolId, int streamId) => _channel.invokeMethod("stop", {
        "poolId": poolId,
        "streamId": streamId,
      });

  @override
  Future<void> pause(int poolId, int streamId) =>
      _channel.invokeMethod("pause", {
        "poolId": poolId,
        "streamId": streamId,
      });

  @override
  Future<void> resume(int poolId, int streamId) =>
      _channel.invokeMethod("resume", {
        "poolId": poolId,
        "streamId": streamId,
      });

  @override
  Future<void> setVolume(int poolId, int? soundId, int? streamId,
          double? volumeLeft, double? volumeRight) =>
      _channel.invokeMethod("setVolume", {
        "poolId": poolId,
        "soundId": soundId,
        "streamId": streamId,
        "volumeLeft": volumeLeft,
        "volumeRight": volumeRight,
      });

  @override
  Future<void> setRate(int poolId, int streamId, double playbackRate) =>
      _channel.invokeMethod("setRate", {
        "poolId": poolId,
        "streamId": streamId,
        "rate": playbackRate,
      });

  @override
  Future<void> dispose(int poolId) => _channel.invokeMethod("dispose", {
        "poolId": poolId,
      }); 

  @override
  Future<void> release(int poolId) =>
      _channel.invokeMethod("release", {"poolId": poolId});
}
