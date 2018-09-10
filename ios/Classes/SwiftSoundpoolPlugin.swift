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
            let wrapper = SoundpoolWrapper()
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
        
        private lazy var soundpool = [AVAudioPlayer]()
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let attributes = call.arguments as! NSDictionary
    switch call.method {
    case "load":
        let rawSound = attributes["rawSound"] as! FlutterStandardTypedData
        do {
        let audioPlayer = try AVAudioPlayer(data: rawSound.data)
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
        let audioPlayer = playerBySoundId(soundId: soundId)
        audioPlayer.numberOfLoops = times ?? 0
        if (audioPlayer.play()) {
            // 0 value means the error (see Android Soundpool API)
            // converting indexes to 1-infinity range
            result(soundId+1)
        } else {
            result(0) // failed to play sound
        }
    case "pause":
        let streamId = attributes["streamId"] as! Int
        let audioPlayer = playerByStreamId(streamId: streamId)
        audioPlayer.pause()
        result(streamId)
    case "stop":
        let streamId = attributes["streamId"] as! Int
        let audioPlayer = playerByStreamId(streamId: streamId)
        audioPlayer.stop()
        result(streamId)
        // resetting player to the begin of the track
        audioPlayer.currentTime = 0.0
        audioPlayer.prepareToPlay()
    case "setVolume":
        let streamId = attributes["streamId"] as? Int
        let soundId = attributes["soundId"] as? Int
        let volume = attributes["volumeLeft"] as! Double
        
        var audioPlayer: AVAudioPlayer? = nil;
        if (streamId != nil){
            audioPlayer = playerByStreamId(streamId: streamId!)
        } else if (soundId != nil){
            audioPlayer = playerBySoundId(soundId: soundId!)
        }
        audioPlayer?.volume = Float(volume)
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
    private func playerByStreamId(streamId: Int) -> AVAudioPlayer {
        // converting streamId to index
        let audioPlayer = soundpool[streamId-1]
        return audioPlayer
    }
    
    private func playerBySoundId(soundId: Int) -> AVAudioPlayer {
        let audioPlayer = soundpool[soundId]
        return audioPlayer
    }
}
}

