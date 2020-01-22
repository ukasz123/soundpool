import Flutter
import UIKit
import AVFoundation

public class SwiftSoundpoolPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pl.ukaszapps/soundpool", binaryMessenger: registrar.messenger())
        let instance = SwiftSoundpoolPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    private lazy var wrappers = [SwiftSoundpoolPlugin.SoundpoolWrapper]()
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initSoundpool":
            // TODO create distinction between different types of audio playback
            let attributes = call.arguments as! NSDictionary
            let maxStreams = attributes["maxStreams"] as! Int
            let wrapper = SoundpoolWrapper(maxStreams)
            let index = wrappers.count
            wrappers.append(wrapper)
            result(index)
        case "dispose":
            let attributes = call.arguments as! NSDictionary
            let index = attributes["poolId"] as! Int
            let wrapper = wrappers[index]
            wrapper.stopAllStreams()
            wrappers.remove(at: index)
            result(nil)
        default:
            let attributes = call.arguments as! NSDictionary
            let index = attributes["poolId"] as! Int
            let wrapper = wrappers[index]
            wrapper.handle(call, result: result)
        }
        
    }
    
    class SoundpoolWrapper : NSObject {
        private var maxStreams: Int
        
        private lazy var soundpool = [AVAudioPlayer]()
        
        private lazy var streamsCount: Dictionary<Int, Int> = [Int: Int]()
        
        private lazy var nowPlaying = [NowPlaying]()
        
        init(_ maxStreams: Int){
            self.maxStreams = maxStreams
        }
        
        public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            let attributes = call.arguments as! NSDictionary
            switch call.method {
            case "load":
                let rawSound = attributes["rawSound"] as! FlutterStandardTypedData
                do {
                    let audioPlayer = try AVAudioPlayer(data: rawSound.data)
                    audioPlayer.enableRate = true
                    audioPlayer.prepareToPlay()
                    let index = soundpool.count
                    soundpool.append(audioPlayer)
                    result(index)
                } catch {
                    result(-1)
                }
            case "loadUri":
                let soundUri = attributes["uri"] as! String
                do {
                    let url = URL(string: soundUri)
                    if (url != nil){
                        let cachedSound = try Data(contentsOf: url!)
                        let audioPlayer = try AVAudioPlayer(data: cachedSound)
                        audioPlayer.enableRate = true
                        audioPlayer.prepareToPlay()
                        let index = soundpool.count
                        soundpool.append(audioPlayer)
                        result(index)
                    } else {
                        result(-1)
                    }
                } catch {
                    result(-1)
                }
            case "play":
                let soundId = attributes["soundId"] as! Int
                let times = attributes["repeat"] as? Int
                let rate = (attributes["rate"] as? Double) ?? 1.0
                var audioPlayer = playerBySoundId(soundId: soundId)
                do {
                    let currentCount = streamsCount[soundId] ?? 0
                    if (currentCount >= maxStreams){
                        result(0)
                        break
                    }
                    if (times != audioPlayer.numberOfLoops || currentCount > 0){
                        // lets recreate the audioPlayer - setting numberOfLoops has initially no effect
                        
                        if let previousData = audioPlayer.data {
                            audioPlayer = try AVAudioPlayer(data: previousData)
                        } else if let previousUrl = audioPlayer.url {
                            audioPlayer = try AVAudioPlayer(contentsOf: previousUrl)
                        }
                        
                        audioPlayer.numberOfLoops = times ?? 0
                        audioPlayer.enableRate = true
                        audioPlayer.prepareToPlay()
                    }
                    let nowPlayingData: NowPlaying
                    
                    if (audioPlayer.delegate == nil){
                        let delegate = SoundpoolDelegate(pool: self, soundId: soundId)
                        audioPlayer.delegate = delegate
                        nowPlayingData =  NowPlaying(player: audioPlayer, delegate: delegate)
                    } else {
                        nowPlayingData = NowPlaying(player: audioPlayer, delegate: audioPlayer.delegate as! SwiftSoundpoolPlugin.SoundpoolWrapper.SoundpoolDelegate)
                    }
                    audioPlayer.rate = Float(rate)
                    
                    if (audioPlayer.play()) {
                        streamsCount[soundId] = currentCount + 1
                        nowPlaying.append(nowPlayingData)
                        result(nowPlaying.count)
                    } else {
                        result(0) // failed to play sound
                    }
                } catch {
                    result(0)
                }
            case "pause":
                let streamId = attributes["streamId"] as! Int
                if let playingData = playerByStreamId(streamId: streamId) {
                    playingData.player.pause()
                    result(streamId)
                } else {
                    result (-1)
                }
            case "resume":
                let streamId = attributes["streamId"] as! Int
                if let playingData = playerByStreamId(streamId: streamId) {
                    playingData.player.play()
                    result(streamId)
                } else {
                    result (-1)
                }
            case "stop":
                let streamId = attributes["streamId"] as! Int
                if let audioPlayer = playerByStreamId(streamId: streamId)?.player {
                    audioPlayer.stop()
                    result(streamId)
                    // resetting player to the begin of the track
                    audioPlayer.currentTime = 0.0
                    audioPlayer.prepareToPlay()
                } else {
                    result(-1)
                }
            case "setVolume":
                let streamId = attributes["streamId"] as? Int
                let soundId = attributes["soundId"] as? Int
                let volume = attributes["volumeLeft"] as! Double
                
                var audioPlayer: AVAudioPlayer? = nil;
                if (streamId != nil){
                    audioPlayer = playerByStreamId(streamId: streamId!)?.player
                } else if (soundId != nil){
                    audioPlayer = playerBySoundId(soundId: soundId!)
                }
                audioPlayer?.volume = Float(volume)
                result(nil)
            case "setRate":
                let streamId = attributes["streamId"] as! Int
                let rate = (attributes["rate"] as? Double) ?? 1.0
                let audioPlayer: AVAudioPlayer? = playerByStreamId(streamId: streamId)?.player
                audioPlayer?.rate = Float(rate)
                result(nil)
            case "release": // TODO this should distinguish between soundpools for different types of audio playbacks
                stopAllStreams()
                soundpool.removeAll()
                result(nil)
            default:
                result("notImplemented")
            }
        }
        
        func stopAllStreams() {
            for audioPlayer in soundpool {
                audioPlayer.stop()
            }
        }
        private func playerByStreamId(streamId: Int) -> NowPlaying? {
            // converting streamId to index
            if (streamId > nowPlaying.count){
                return nil
            }
            let audioPlayer = nowPlaying[streamId-1]
            return audioPlayer
        }
        
        private func playerBySoundId(soundId: Int) -> AVAudioPlayer {
            let audioPlayer = soundpool[soundId]
            return audioPlayer
        }
        
        private class SoundpoolDelegate: NSObject, AVAudioPlayerDelegate {
            private var soundId: Int
            private var pool: SoundpoolWrapper
            init(pool: SoundpoolWrapper, soundId: Int) {
                self.soundId = soundId
                self.pool = pool
            }
            func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
                decreaseCounter()
            }
            private func decreaseCounter(){
                pool.streamsCount[soundId] = (pool.streamsCount[soundId] ?? 1) - 1
                let toRemove = pool.nowPlaying.filter({$0.delegate == self})
                toRemove.forEach {
                    $0.player.delegate = nil
                }
                pool.nowPlaying.removeAll{
                    $0.delegate == self
                }
            }
        }
        
        private struct NowPlaying {
            let player: AVAudioPlayer
            let delegate: SoundpoolDelegate
        }
    }
}

