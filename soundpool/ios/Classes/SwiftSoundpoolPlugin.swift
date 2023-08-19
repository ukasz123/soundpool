import Flutter
import UIKit
import AVFoundation


public class SwiftSoundpoolPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pl.ukaszapps/soundpool", binaryMessenger: registrar.messenger())
        let instance = SwiftSoundpoolPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private let counter = Atomic<Int>(0)
    
    private lazy var wrappers = Dictionary<Int,SwiftSoundpoolPlugin.SoundpoolWrapper>()
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initSoundpool":
            // TODO create distinction between different types of audio playback
            let attributes = call.arguments as! NSDictionary
            
            initAudioSession(attributes)
            
            let maxStreams = attributes["maxStreams"] as! Int
            let enableRate = (attributes["ios_enableRate"] as? Bool) ?? true
            let wrapper = SoundpoolWrapper(maxStreams, enableRate)
            
            let index = counter.increment()
            wrappers[index] = wrapper;
            result(index)
        case "dispose":
            let attributes = call.arguments as! NSDictionary
            let index = attributes["poolId"] as! Int
            
            guard let wrapper = wrapperById(id: index) else {
                print("Dispose attempt on not available pool (id: \(index)).")
                result(FlutterError( code: "invalidArgs",
                                     message: "Invalid poolId",
                                     details: "Pool with id \(index) not found" ))
                break
            }
            wrapper.stopAllStreams()
            wrappers.removeValue(forKey: index)
            result(nil)
        default:
            let attributes = call.arguments as! NSDictionary
            let index = attributes["poolId"] as! Int
            
            guard let wrapper = wrapperById(id: index) else {
                print("Action '\(call.method)' attempt on not available pool (id: \(index)).")
                result(FlutterError( code: "invalidArgs",
                                     message: "Invalid poolId",
                                     details: "Pool with id \(index) not found" ))
                break
            }
            wrapper.handle(call, result: result)
        }
    }
    
    private func initAudioSession(_ attributes: NSDictionary) {
        if #available(iOS 10.0, *) {
            // guard against audio_session plugin and avoid doing redundant session management
            if (NSClassFromString("AudioSessionPlugin") != nil) {
                print("AudioSession should be managed by 'audio_session' plugin")
                return
            }
            
            
            guard let categoryAttr = attributes["ios_avSessionCategory"] as? String else {
                return
            }
            let modeAttr = attributes["ios_avSessionMode"] as! String
            
            let category: AVAudioSession.Category
            switch categoryAttr {
            case "ambient":
                category = .ambient
            case "playback":
                category = .playback
            case "playAndRecord":
                category = .playAndRecord
            case "multiRoute":
                category = .multiRoute
            default:
                category = .soloAmbient
                
            }
            let mode: AVAudioSession.Mode
            switch modeAttr {
            case "moviePlayback":
                mode = .moviePlayback
            case "videoRecording":
                mode = .videoRecording
            case "voiceChat":
                mode = .voiceChat
            case "gameChat":
                mode = .gameChat
            case "videoChat":
                mode = .videoChat
            case "spokenAudio":
                mode = .spokenAudio
            case "measurement":
                mode = .measurement
            default:
                mode = .default
            }
            do {
                try AVAudioSession.sharedInstance().setCategory(category, mode: mode)
                print("Audio session updated: category = '\(category)', mode = '\(mode)'.")
            } catch (let e) {
                //do nothing
                print("Error while trying to set audio category: '\(e)'")
            }
        }
    }
    
    private func wrapperById(id: Int) -> SwiftSoundpoolPlugin.SoundpoolWrapper? {
        if (id < 0){
            return nil
        }
        let wrapper = wrappers[id]
        return wrapper
    }
    
    class SoundpoolWrapper : NSObject {
        private var maxStreams: Int
        
        private var enableRate: Bool
        
        private var streamIdProvider = Atomic<Int>(0)
        
        private lazy var soundpool = [AVAudioPlayer]()
        
        private lazy var streamsCount: Dictionary<Int, Int> = [Int: Int]()
        
        private lazy var nowPlaying: Dictionary<Int, NowPlaying> = [Int: NowPlaying]()
        
        init(_ maxStreams: Int, _ enableRate: Bool){
            self.maxStreams = maxStreams
            self.enableRate = enableRate
        }
        
        public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            let attributes = call.arguments as! NSDictionary
            //            print("\(call.method): \(attributes)")
            switch call.method {
            case "load":
                let rawSound = attributes["rawSound"] as! FlutterStandardTypedData
                do {
                    let audioPlayer = try AVAudioPlayer(data: rawSound.data)
                    if (enableRate){
                        audioPlayer.enableRate = true
                    }
                    audioPlayer.prepareToPlay()
                    let index = soundpool.count
                    soundpool.append(audioPlayer)
                    result(index)
                } catch {
                    result(-1)
                }
            case "loadUri":
                let soundUri = attributes["uri"] as! String
                
                let url = URL(string: soundUri)
                if (url != nil){
                    DispatchQueue.global(qos: .utility).async {
                        do {
                            let cachedSound = try Data(contentsOf: url!, options: NSData.ReadingOptions.mappedIfSafe)
                            DispatchQueue.main.async {
                                var value:Int = -1
                                do {
                                    let audioPlayer = try AVAudioPlayer(data: cachedSound)
                                    if (self.enableRate){
                                        audioPlayer.enableRate = true
                                    }
                                    audioPlayer.prepareToPlay()
                                    let index = self.self.soundpool.count
                                    self.self.soundpool.append(audioPlayer)
                                    value = index
                                } catch {
                                    print("Unexpected error while preparing player: \(error).")
                                }
                                result(value)
                            }
                        } catch {
                            print("Unexpected error while downloading file: \(error).")
                            DispatchQueue.main.async {
                                result(-1)
                            }
                        }
                    }
                } else {
                    result(-1)
                }
            case "play":
                let soundId = attributes["soundId"] as! Int
                let times = attributes["repeat"] as? Int
                let rate = (attributes["rate"] as? Double) ?? 1.0
                if (soundId < 0){
                    result(0)
                    break
                }
                
                guard var audioPlayer = playerBySoundId(soundId: soundId) else {
                    result(0)
                    break
                }
                do {
                    let currentCount = streamsCount[soundId] ?? 0
                    
                    if (currentCount >= maxStreams){
                        result(0)
                        break
                    }
                    
                    let nowPlayingData: NowPlaying
                    let streamId: Int = streamIdProvider.increment()
                    
                    let delegate = SoundpoolDelegate(pool: self, soundId: soundId, streamId: streamId)
                    audioPlayer.delegate = delegate
                    nowPlayingData =  NowPlaying(player: audioPlayer, delegate: delegate)
                    
                    audioPlayer.numberOfLoops = times ?? 0
                    if (enableRate){
                        audioPlayer.enableRate = true
                        audioPlayer.rate = Float(rate)
                    }
                    
                    if (audioPlayer.play()) {
                        streamsCount[soundId] = currentCount + 1
                        nowPlaying[streamId] = nowPlayingData
                        result(streamId)
                    } else {
                        result(0) // failed to play sound
                    }
                    // lets recreate the audioPlayer for next request - setting numberOfLoops has initially no effect
                    
                    if let previousData = audioPlayer.data {
                        audioPlayer = try AVAudioPlayer(data: previousData)
                    } else if let previousUrl = audioPlayer.url {
                        audioPlayer = try AVAudioPlayer(contentsOf: previousUrl)
                    }
                    if (enableRate){
                        audioPlayer.enableRate = true
                    }
                    audioPlayer.prepareToPlay()
                    soundpool[soundId] = audioPlayer
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
                if let nowPlaying = playerByStreamId(streamId: streamId) {
                    let audioPlayer = nowPlaying.player
                    audioPlayer.stop()
                    result(streamId)
                    // removing player
                    self.nowPlaying.removeValue(forKey: streamId)
                    nowPlaying.delegate.decreaseCounter()
                    audioPlayer.delegate = nil
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
                if (enableRate){
                    let streamId = attributes["streamId"] as! Int
                    let rate = (attributes["rate"] as? Double) ?? 1.0
                    let audioPlayer: AVAudioPlayer? = playerByStreamId(streamId: streamId)?.player
                    audioPlayer?.rate = Float(rate)
                }
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
            let audioPlayer = nowPlaying[streamId]
            return audioPlayer
        }
        
        private func playerBySoundId(soundId: Int) -> AVAudioPlayer? {
            if (soundId >= soundpool.count || soundId < 0){
                return nil
            }
            let audioPlayer = soundpool[soundId]
            return audioPlayer
        }
        
        private class SoundpoolDelegate: NSObject, AVAudioPlayerDelegate {
            private var soundId: Int
            private var streamId: Int
            private var pool: SoundpoolWrapper
            init(pool: SoundpoolWrapper, soundId: Int, streamId: Int) {
                self.soundId = soundId
                self.pool = pool
                self.streamId = streamId
            }
            func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
                decreaseCounter()
            }
            func decreaseCounter(){
                pool.streamsCount[soundId] = (pool.streamsCount[soundId] ?? 1) - 1
                pool.nowPlaying.removeValue(forKey: streamId)
            }
        }
        
        private struct NowPlaying {
            let player: AVAudioPlayer
            let delegate: SoundpoolDelegate
        }
    }
}

