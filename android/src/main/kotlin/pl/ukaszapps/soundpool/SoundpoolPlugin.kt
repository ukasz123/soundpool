package pl.ukaszapps.soundpool

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.FileOutputStream

class SoundpoolPlugin : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            channel.setMethodCallHandler(SoundpoolPlugin())
        }

        private const val CHANNEL_NAME = "pl.ukaszapps/soundpool"

        private val DEFAULT_VOLUME_INFO = VolumeInfo()
    }

    private val soundPool by lazy {
        return@lazy if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            SoundPool.Builder().setAudioAttributes(AudioAttributes.Builder().setLegacyStreamType
            (AudioManager.STREAM_MUSIC).setUsage(AudioAttributes.USAGE_GAME).build())
                    .build()
        } else {
            SoundPool(1, AudioManager.STREAM_MUSIC, 1)
        }
    }

    private val volumeSettings = mutableMapOf<Int, VolumeInfo>()


    private fun volumeSettingsForSoundId(soundId: Int): VolumeInfo =
    volumeSettings[soundId] ?: DEFAULT_VOLUME_INFO;


    override fun onMethodCall(call: MethodCall, result: Result) {

        when (call.method) {
            "load" -> {
                val arguments = call.arguments as Map<String, Any>
                val soundData = arguments["rawSound"] as ByteArray
                val priority = arguments["priority"] as Int
                val tempFile = createTempFile(prefix = "sound", suffix = "pool")
                FileOutputStream(tempFile).use {
                    it.write(soundData)
                }
                tempFile.deleteOnExit()
                val soundId = soundPool.load(tempFile.absolutePath, priority)
                result.success(soundId)
            }
            "release" -> {
                soundPool.release()
            }
            "play" -> {
                val arguments = call.arguments as Map<String, Int>
                val soundId = arguments["soundId"]!!
                val repeat = arguments["repeat"] ?: 0
                val volumeInfo = volumeSettingsForSoundId(soundId = soundId)
                val streamId = soundPool.play(soundId, volumeInfo.left, volumeInfo.right, 0,
                        repeat, 1.0f)
                result.success(streamId)
            }
            "pause" -> {
                val arguments = call.arguments as Map<String, Int>
                val streamId = arguments["streamId"]!!
                soundPool.pause(streamId)
                result.success(streamId)
            }
            "stop" -> {
                val arguments = call.arguments as Map<String, Int>
                val streamId = arguments["streamId"]!!
                soundPool.stop(streamId)
                result.success(streamId)
            }
            "setVolume" -> {
                val arguments = call.arguments as Map<String, Any?>
                val streamId: Int? = arguments["streamId"] as Int?
                val soundId: Int? = arguments["soundId"] as Int?
                if (streamId == null && soundId == null){
                    result.error("InvalidParameters", "Either 'streamId' or 'soundId' has to be " +
                            "passed", null)
                }
                val volumeLeft: Double = arguments["volumeLeft"]!! as Double
                val volumeRight: Double = arguments["volumeRight"]!! as Double

                streamId?.let{
                    soundPool.setVolume(it, volumeLeft.toFloat(), volumeRight.toFloat())
                }
                soundId?.let {
                    volumeSettings[it] = VolumeInfo(left = volumeLeft.toFloat(), right =
                    volumeRight.toFloat())
                }
            }
            else -> result.notImplemented()
        }
    }
}

internal data class VolumeInfo(val left: Float = 1.0f, val right: Float = 1.0f);
