package pl.ukaszapps.soundpool

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.SoundPool
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.net.URI
import java.util.concurrent.*


internal val loadExecutor: Executor = Executors.newCachedThreadPool()

internal val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

class SoundpoolPlugin : MethodCallHandler, FlutterPlugin {
    companion object {
        private const val CHANNEL_NAME = "pl.ukaszapps/soundpool"
    }

    private fun onRegister(context: Context,  messenger: BinaryMessenger) {
        application = context.applicationContext
        val channel = MethodChannel(messenger, CHANNEL_NAME)

        channel.setMethodCallHandler(this)

        // clearing temporary files from previous session
        with(application.cacheDir) { this?.list { _, name -> name.matches("sound(.*)pool".toRegex()) }?.forEach { File(this, it).delete() } }
    }

    private lateinit var  application : Context

    private val wrappers: MutableList<SoundpoolWrapper> = mutableListOf()

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initSoundpool" -> {
                val arguments = call.arguments as Map<String, Int>
                val streamTypeIndex = arguments["streamType"]
                val maxStreams = arguments["maxStreams"] ?: 1
                val streamType = when (streamTypeIndex) {
                    0 -> AudioManager.STREAM_RING
                    1 -> AudioManager.STREAM_ALARM
                    2 -> AudioManager.STREAM_MUSIC
                    3 -> AudioManager.STREAM_NOTIFICATION
                    else -> -1
                }
                if (streamType > -1) {
                    val wrapper = SoundpoolWrapper(application, maxStreams, streamType)
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
                wrappers[poolIndex].dispose()
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

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        onRegister(binding.applicationContext, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        wrappers.forEach { it.dispose() }
        wrappers.clear()
    }

}

internal data class VolumeInfo(val left: Float = 1.0f, val right: Float = 1.0f);

/**
 * Wraps Soundpool instance and handles instance-level method calls
 */
internal class SoundpoolWrapper(private val context: Context, private val maxStreams: Int, private val streamType: Int) {
    companion object {

        private val DEFAULT_VOLUME_INFO = VolumeInfo()
    }

    private var soundPool = createSoundpool()

    private val loadingSoundsMap = HashMap<Int, Result>()

    private inline fun ui(crossinline block: () -> Unit) {
        uiThreadHandler.post { block() }
    }

    private var threadPool: ExecutorService = ThreadPoolExecutor(1, maxStreams, 1, TimeUnit.SECONDS, LinkedBlockingDeque())

    private inline fun runBg(crossinline block: () -> Unit) {
        threadPool.execute { block() }
    }

    private fun createSoundpool() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        val usage = when (streamType) {
            AudioManager.STREAM_RING -> AudioAttributes.USAGE_NOTIFICATION_RINGTONE
            AudioManager.STREAM_ALARM -> android.media.AudioAttributes.USAGE_ALARM
            AudioManager.STREAM_NOTIFICATION -> android.media.AudioAttributes.USAGE_NOTIFICATION
            else -> android.media.AudioAttributes.USAGE_GAME
        }
        SoundPool.Builder()
                .setMaxStreams(maxStreams)
                .setAudioAttributes(AudioAttributes.Builder().setLegacyStreamType
                (streamType)
                        .setUsage(usage)
                        .build())
                .build()
    } else {
        SoundPool(maxStreams, streamType, 1)
    }.apply {
        setOnLoadCompleteListener { _, sampleId, status ->
            val resultCallback = loadingSoundsMap[sampleId]
            resultCallback?.let {
                ui {
                    if (status == 0) {
                        it.success(sampleId)
                    } else {
                        it.error("Loading failed", "Error code: $status", null)
                    }
                }
                loadingSoundsMap.remove(sampleId)

            }

        }

    }

    private val volumeSettings = mutableMapOf<Int, VolumeInfo>()


    private fun volumeSettingsForSoundId(soundId: Int): VolumeInfo =
            volumeSettings[soundId] ?: DEFAULT_VOLUME_INFO

    internal fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "load" -> {
                loadExecutor.execute {
                    try {
                        val arguments = call.arguments as Map<String, Any>
                        val soundData = arguments["rawSound"] as ByteArray
                        val priority = arguments["priority"] as Int
                        val tempFile = createTempFile(prefix = "sound", suffix = "pool", directory = context.cacheDir)
                        FileOutputStream(tempFile).use {
                            it.write(soundData)
                            tempFile.deleteOnExit()
                            val soundId = soundPool.load(tempFile.absolutePath, priority)
//                    result.success(soundId)
                            if (soundId > -1) {
                                loadingSoundsMap[soundId] = result
                            } else {
                                ui { result.success(soundId) }
                            }
                        }
                    } catch (t: Throwable) {
                        ui { result.error("Loading failure", t.message, null) }
                    }
                }
            }
            "loadUri" -> {
                loadExecutor.execute {
                    try {
                        val arguments = call.arguments as Map<String, Any>
                        val soundUri = arguments["uri"] as String
                        val priority = arguments["priority"] as Int
                        val soundId =
                                URI.create(soundUri).let { uri ->
                                    return@let if (uri.scheme == "content") {
                                        soundPool.load(context.contentResolver.openAssetFileDescriptor(Uri.parse(soundUri), "r"), 1)
                                    } else {
                                        val tempFile = createTempFile(prefix = "sound", suffix = "pool", directory = context.cacheDir)
                                        FileOutputStream(tempFile).use { out ->
                                            out.write(uri.toURL().readBytes())
                                        }
                                        tempFile.deleteOnExit()
                                        soundPool.load(tempFile.absolutePath, priority)
                                    }
                                }

                        if (soundId > -1) {
                            loadingSoundsMap[soundId] = result
                        } else {
                            ui { result.success(soundId) }
                        }
                    } catch (t: Throwable) {
                        ui { result.error("URI loading failure", t.message, null) }
                    }
                }
            }
            "release" -> {
                releaseSoundpool()
                soundPool = createSoundpool()
                result.success(null)
            }
            "play" -> {
                val arguments = call.arguments as Map<String, Any>
                val soundId: Int = (arguments["soundId"] as Int?)!!
                val repeat: Int = arguments["repeat"] as Int? ?: 0
                val rate: Double = arguments["rate"] as Double? ?: 1.0
                val volumeInfo = volumeSettingsForSoundId(soundId = soundId)
                runBg {
                    val streamId = soundPool.play(soundId, volumeInfo.left, volumeInfo.right, 0,
                            repeat, rate.toFloat())
                    ui {
                        result.success(streamId)
                    }
                }
            }
            "pause" -> {
                val arguments = call.arguments as Map<String, Int>
                val streamId = arguments["streamId"]!!
                runBg {
                    soundPool.pause(streamId)
                    ui {
                        result.success(streamId)
                    }
                }
            }
            "resume" -> {
                val arguments = call.arguments as Map<String, Int>
                val streamId = arguments["streamId"]!!
                runBg {
                    soundPool.resume(streamId)
                    ui { result.success(streamId) }
                }
            }
            "stop" -> {
                val arguments = call.arguments as Map<String, Int>
                val streamId = arguments["streamId"]!!
                runBg {
                    soundPool.stop(streamId)
                    ui { result.success(streamId) }
                }
            }
            "setVolume" -> {
                val arguments = call.arguments as Map<String, Any?>
                val streamId: Int? = arguments["streamId"] as Int?
                val soundId: Int? = arguments["soundId"] as Int?
                if (streamId == null && soundId == null) {
                    result.error("InvalidParameters", "Either 'streamId' or 'soundId' has to be " +
                            "passed", null)
                }
                val volumeLeft: Double = arguments["volumeLeft"]!! as Double
                val volumeRight: Double = arguments["volumeRight"]!! as Double
                runBg {
                    streamId?.let {
                        soundPool.setVolume(it, volumeLeft.toFloat(), volumeRight.toFloat())
                    }
                    soundId?.let {
                        volumeSettings[it] = VolumeInfo(left = volumeLeft.toFloat(), right =
                        volumeRight.toFloat())
                    }
                    ui { result.success(null) }
                }
            }
            "setRate" -> {

                val arguments = call.arguments as Map<String, Any?>
                val streamId: Int = arguments["streamId"]!! as Int
                val rate: Double = arguments["rate"] as Double? ?: 1.0
                runBg {
                    soundPool.setRate(streamId, rate.toFloat())
                    ui { result.success(null) }
                }
            }
            else -> result.notImplemented()
        }
    }

    internal fun dispose() {
        releaseSoundpool()
        threadPool.shutdownNow()
    }

    internal fun releaseSoundpool() {
        soundPool.release()

    }
}
