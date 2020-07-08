package com.madlonkay.flutter_tex_js

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel

/** FlutterTexJsPlugin */
public class FlutterTexJsPlugin : FlutterPlugin, MethodCallHandler, CoroutineScope by MainScope() {
    private lateinit var channel: MethodChannel
    private lateinit var renderer: TexRenderer

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_tex_js")
        channel.setMethodCallHandler(this)
        renderer = TexRenderer(flutterPluginBinding.applicationContext)
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_tex_js")
            channel.setMethodCallHandler(FlutterTexJsPlugin())
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "render" -> handleRender(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        cancel("onDetatchedFromEngine")
        renderer.cancel("onDetatchedFromEngine")
    }

    private fun handleRender(call: MethodCall, result: Result) {
        val requestId = call.argument<String>("requestId")
        if (requestId == null) {
            result.error("Missing Arg", "Required argument missing", "${call.method} requires 'requestId'")
            return
        }
        val text = call.argument<String>("text")
        if (text == null) {
            result.error("Missing Arg", "Required argument missing", "${call.method} requires 'text'")
            return
        }
        val displayMode = call.argument<Boolean>("displayMode")
        if (displayMode == null) {
            result.error("Missing Arg", "Required argument missing", "${call.method} requires 'displayMode'")
            return
        }
        val color = call.argument<String>("color")
        if (color == null) {
            result.error("Missing Arg", "Required argument missing", "${call.method} requires 'color'")
            return
        }
        val maxWidth = call.argument<Double>("maxWidth")
        if (maxWidth == null) {
            result.error("Missing Arg", "Required argument missing", "${call.method} requires 'maxWidth'")
            return
        }

        Log.d("AMK", "Queued $requestId")

        Log.d("AMK", "Starting on thread ${Thread.currentThread()}")
        renderer.whenReady {
            Log.d("AMK", "Now ready; job=$requestId; thread=${Thread.currentThread()}")
            it.render(text, displayMode, color, maxWidth) { bytes, error ->
                Log.d("AMK", "Now back from render; job=$requestId; thread=${Thread.currentThread()}")
                if (bytes != null) {
                    result.success(bytes)
                } else {
                    result.error(error!!.code, error.message, error.details)
                }
            }
        }
    }
}
