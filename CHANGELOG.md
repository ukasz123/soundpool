## 0.5.0 (20-03-2019)
* `maxStreams` parameter added to the constructor (_Android only feature_)
(thanks to [niusounds](https://github.com/niusounds))
#### 0.5.1
* Gradle plugin upgraded
* Kotlin upgraded
* Dependency to Android Support library was removed
* Swift version upgraded

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

