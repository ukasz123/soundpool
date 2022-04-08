/// Soundpool options for iOS devices
class SoundpoolOptionsIos {
  static const kDefault = SoundpoolOptionsIos();

  /// When set the `rate` value in [Soundpool.play] and [Soundpool.setRate] wound have effect
  /// Default value: `true`
  final bool enableRate;

  const SoundpoolOptionsIos({
    this.enableRate = true,
  });

  Map<String, dynamic> toOptionsMap() => {
        'enableRate': enableRate,
      };
}
