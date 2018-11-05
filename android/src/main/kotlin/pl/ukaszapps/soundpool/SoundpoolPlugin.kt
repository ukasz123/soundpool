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
import java.net.URI
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class SoundpoolPlugin : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            channel.setMethodCallHandler(SoundpoolPlugin())
        }

        private const val CHANNEL_NAME = "pl.ukaszapps/soundpool"
    }
    private val wrappers : MutableList<SoundpoolWrapper> = mutableListOf()

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initSoundpool" -> {
                val arguments = call.arguments as Map<String, Int>
                val streamTypeIndex = arguments["streamType"]
                val streamType = when(streamTypeIndex){
                    0 -> AudioManager.STREAM_RING
                    1 -> AudioManager.STREAM_ALARM
                    2 -> AudioManager.STREAM_MUSIC
                    3 -> AudioManager.STREAM_NOTIFICATION
                    else -> -1
                }
                if (streamType > -1){
                    val wrapper = SoundpoolWrapper(streamType)
                    val index = wrappers.size
                    wrappers.add(wrapper)
                    result.success(index)
                } else {
                    result.success(-1)
                }
            }
            "dispose" -> {
                val arguments = call.arguments as Map<String, Int>
                val poolIndex = arguments["poolId"]!!
                wrappers[poolIndex].releaseSoundpool()
                wrappers.removeAt(poolIndex)
                result.success(null)
            }
            else -> {
                val arguments = call.arguments as Map<String, Any>
                val poolIndex = arguments["poolId"] as Int
                wrappers[poolIndex].onMethodCall(call, result)
            }
        }
    }
}

internal data class VolumeInfo(val left: Float = 1.0f, val right: Float = 1.0f);

/**
 * Wraps Soundpool instance and handles instance-level method calls
 */
internal class SoundpoolWrapper (private val streamType: Int) {
    companion object {

        private val DEFAULT_VOLUME_INFO = VolumeInfo()

        private val loadExecutor: Executor by lazy { Executors.newCachedThreadPool() }
    }

    private var soundPool = createSoundpool()


    private fun createSoundpool() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        val usage = when(streamType){
            AudioManager.STREAM_RING -> AudioAttributes.USAGE_NOTIFICATION_RINGTONE
            AudioManager.STREAM_ALARM -> android.media.AudioAttributes.USAGE_ALARM
            AudioManager.STREAM_NOTIFICATION -> android.media.AudioAttributes.USAGE_NOTIFICATION
            else -> android.media.AudioAttributes.USAGE_GAME
        }
        SoundPool.Builder().setAudioAttributes(AudioAttributes.Builder().setLegacyStreamType
        (streamType)
                .setUsage(usage)
                .build())
                .build()
    } else {
        SoundPool(1, streamType, 1)
    }

    private val volumeSettings = mutableMapOf<Int, VolumeInfo>()


    private fun volumeSettingsForSoundId(soundId: Int): VolumeInfo =
            volumeSettings[soundId] ?: DEFAULT_VOLUME_INFO

    internal fun onMethodCall(call: MethodCall, result: Result) {

        when (call.method) {
            "load" -> {
                loadExecutor.execute {
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
            }
            "loadUri" -> {
                loadExecutor.execute {
	                try {
		                val arguments = call.arguments as Map<String, Any>
		                val soundUri = arguments["uri"] as String
		                val priority = arguments["priority"] as Int
		                val tempFile = createTempFile(prefix = "sound", suffix = "pool")
		                FileOutputStream(tempFile).use {
			                it.write(URI.create(soundUri).toURL().readBytes())
		                }
		                tempFile.deleteOnExit()
		                val soundId = soundPool.load(tempFile.absolutePath, priority)
		                result.success(soundId)
	                } catch (t: Throwable){
		                result.error("URI loading failure", t.message, t)
	                }
                }
            }
            "release" -> {
                releaseSoundpool()
                soundPool = createSoundpool()
                result.success(null)
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
            "resume" -> {
                val arguments = call.arguments as Map<String, Int>
                val streamId = arguments["streamId"]!!
                soundPool.resume(streamId)
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
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    internal fun releaseSoundpool() {
        soundPool.release()
    }
}
