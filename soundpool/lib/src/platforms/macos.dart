/// Soundpool options for MacOS
class SoundpoolOptionsMacos {
  static const kDefault = SoundpoolOptionsMacos();

  /// When set the `rate` value in [Soundpool.play] and [Soundpool.setRate] wound have effect
  /// Default value: `true`
  final bool enableRate;

  const SoundpoolOptionsMacos({this.enableRate = true});

  Map<String, dynamic> toOptionsMap() => {
        'enableRate': enableRate,
      };
}
