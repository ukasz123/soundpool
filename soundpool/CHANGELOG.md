## 2.4.1
* Support AGP 8.0 (fixes [#121](https://github.com/ukasz123/soundpool/issues/121), thanks to [MrCsabaToth](https://github.com/MrCsabaToth)). 
## 2.4.0
* Update for **Dart 3.0** and **Flutter 3.10**
* **(iOS)** Skip `AVAudioSession` configuration when [`audio_session`](https://pub.dev/packages/audio_session) plugin has been detected. Audio session should be managed through that plugin instead (Fixes [#99](https://github.com/ukasz123/soundpool/pull/99)).
## 2.3.0
* Update for **Flutter 2.10**
## 2.2.0
* Platform-specific options:
    - iOS: support for configuring [AVAudioSession](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioSessionCategoriesandModes/AudioSessionCategoriesandModes.html#//apple_ref/doc/uid/TP40007875-CH10)
        - `audioSessionCategory` - sets [AVAudioSession.Category](https://developer.apple.com/documentation/avfaudio/avaudiosession/category)
        - `audioSessionMode` - sets [AVAudioSession.Mode](https://developer.apple.com/documentation/avfaudio/avaudiosession/mode)
* Bugfix: disposing a pool and creating a new one could end with an invalid state on iOS and MacOS
* Updated Android pipeline

## 2.1.0
* Platform-specific options:
    - `enableRate` option for iOS and MacOS - when set to `false` Soundpool would ignore playback rate values
* Android Soundpool plays sounds on separate thread.

## 2.0.0-nullsafety.0
* Null-safety support

### 1.1.3
* Bugfix (iOS & MacOS): Guard against invalid values of `poolId`

### 1.1.2
* Bugfix (iOS): Guard against invalid values of `soundId`
* Add note about error value returned from `loadXXX` methods

### 1.1.1
* Bugfix (iOS): `stop()` not working correctly sometimes

## 1.1.0
* **MacOS support**
* Bugfix (iOS): sound not played anymore after calling `stop()`
* iOS: Loading sound file from URL is done in `.uitility` queue instead of `main`
* Multiple assertions added to help debugging app

### 1.0.1
* Homepage url fix
## 1.0.0 (21-02-2020)
* Migrated to use platform interface

### 0.6.1 (22-01-2020)
* Playback rate control
** set in advance with `play()`
** update while playing with `setRate()`

## 0.6.0 (04-01-2020)
* **BREAKING CHANGE:** Web support (limited)
    * Unavailable:
        * `pause()`/`resume()` functions crashes
        * `streamType` parameter has no effect
        * `maxStreams` parameter has no effect - there is no limit on simultanously played sounds

## 0.5.0 (20-03-2019)
* `maxStreams` parameter added to the constructor (_Android only feature_)
(thanks to [niusounds](https://github.com/niusounds))
#### 0.5.1
* Gradle plugin upgraded
* Kotlin upgraded
* Dependency to Android Support library was removed
* Swift version upgraded
#### 0.5.2 (28-05-2019)
* Handle content:// schema on Android
* Run callbacks on UI thread
#### 0.5.3 (03-06-2019)
* Set Swift version in plugin's podspec
#### 0.5.4 (04-01-2020)
* Clear temporary files from previous session (_Android_)
* Emulate `maxStreams` parameter on _iOS_

## 0.4.0 (04-03-2019)
* Methods for immediate playback after loading
* Documentation update
#### 0.4.1 (06-03-2019)
* Android bugs fixed

## 0.3.0 (11-12-2018)
* Upgrade Android Gradle plugin

## 0.2.0 (05-11-2018)
* New methods for controlling audio stream:
    * stop
    * pause
    * resume
* Fixed iOS problem with `repeat` parameter not working on the first `play()` call
* Stream handling wrapper API

### 0.1.1 (16-09-2018)
* Fix type cast error in play() (thanks to [SpencerCornish](https://github.com/SpencerCornish))

## 0.1.0 (10-09-2018)
* **Breaking change**
    * Multiple soundpools support
    * Audio stream type may be defined for Soundpool to use (_Android only_)
        * Every sound loaded for the Soundpool is played on the audio stream Soundpool instace was created with
* Fix Android app crashing when URI is not reachable

## 0.0.3 (19-06-2018)
* Load sound files from URI
* Fix `setVolume()` and `release()` never finishing

## 0.0.1 (10-06-2018)

* Initial release.
    * Loading sound files from assets.
    * Playing, stopping and pausing streams.
    * Releasing resources.
* Works on Android and iOS.
