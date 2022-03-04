package pl.ukaszapps.soundpoolexample

import android.content.res.AssetManager
import android.media.AudioManager
import android.os.Bundle
import android.util.Log
import android.view.GestureDetector
import android.view.GestureDetector.SimpleOnGestureListener
import android.view.MotionEvent
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import pl.ukaszapps.soundpool.SoundpoolWrapper


class MainNativeActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main_native)
        val poolPlugin = SoundpoolWrapper(this, 1, AudioManager.STREAM_MUSIC)

        val am: AssetManager = getAssets()
        val stream = am.open("bad-drum-punchy-snare.wav")
        val bytes = stream.readBytes()
        val context = applicationContext
        poolPlugin.onMethodCall(MethodCall(
            "load", mapOf(
                "rawSound" to bytes,
                "priority" to 1
            )
        ), object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.i("flutter", "sound loaded: $result")
                val soundId = result as Int
                val view = findViewById<View>(R.id.button);
                val listener: SimpleOnGestureListener = object : SimpleOnGestureListener() {
                    override fun onDown(e: MotionEvent?): Boolean {
                        Log.i(
                            "flutter",
                            "${System.currentTimeMillis()} - BENCHMARKING: native down pressed"
                        )
                        poolPlugin.onMethodCall(MethodCall(
                            "play", mapOf(
                                "soundId" to soundId,

                                )
                        ), object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                Log.i(
                                    "flutter",
                                    "${System.currentTimeMillis()} - BENCHMARKING: native sound played"
                                )
                            }

                            override fun error(
                                errorCode: String?,
                                errorMessage: String?,
                                errorDetails: Any?
                            ) {
                                Log.w("flutter", "error: $errorCode, $errorMessage")
                            }

                            override fun notImplemented() {
                                TODO("Not yet implemented")
                            }

                        })
                        return super.onDown(e)
                    }
                }
                val gestureDetector = GestureDetector(
                    context,
                    listener
                )
                view.setOnTouchListener { view, motionEvent ->
                    gestureDetector.onTouchEvent(motionEvent)
                    view.performClick()
                }
            }

            override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
                TODO("Not yet implemented")
            }

            override fun notImplemented() {
                TODO("Not yet implemented")
            }

        })
    }
}