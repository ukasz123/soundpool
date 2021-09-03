/// Soundpool options for iOS devices
class SoundpoolOptionsIos {
  static const kDefault = SoundpoolOptionsIos();

  /// When set the `rate` value in [Soundpool.play] and [Soundpool.setRate] wound have effect
  /// Default value: `true`
  final bool enableRate;

  /// Audio Session category for shared [AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)
  final AudioSessionCategory? audioSessionCategory;

  /// Audio Session mode for shared [AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)
  final AudioSessionMode audioSessionMode;

  const SoundpoolOptionsIos({
    this.enableRate = true,
    this.audioSessionCategory,
    this.audioSessionMode = AudioSessionMode.normal,
  });

  Map<String, dynamic> toOptionsMap() => {
        'enableRate': enableRate,
        'avSessionCategory': audioSessionCategory?.toString().split('.').last,
        'avSessionMode': audioSessionMode.toString().split('.').last,
      };
}

/// See:
/// - [Audio Session Categories and Modes](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html#//apple_ref/doc/uid/TP40007875-CH10)
/// - [Audio Session Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionBasics/AudioSessionBasics.html#//apple_ref/doc/uid/TP40007875-CH3-SW1)
enum AudioSessionCategory {
  ambient,
  soloAmbient,
  playback,
  playAndRecord,
  multiRoute,
}

/// See:
/// - [Audio Session Categories and Modes](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html#//apple_ref/doc/uid/TP40007875-CH10)
/// - [Audio Session Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionBasics/AudioSessionBasics.html#//apple_ref/doc/uid/TP40007875-CH3-SW1)
enum AudioSessionMode {
  /// 'Default' mode
  normal,
  moviePlayback,
  videoRecording,
  voiceChat,
  gameChat,
  videoChat,
  spokenAudio,
  measurement,
}
