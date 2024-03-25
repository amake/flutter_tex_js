package com.madlonkay.flutter_tex_js

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import java.util.concurrent.ConcurrentHashMap

/** FlutterTexJsPlugin */
public class FlutterTexJsPlugin : FlutterPlugin, MethodCallHandler, CoroutineScope by MainScope() {
    private lateinit var channel: MethodChannel
    private lateinit var renderer: TexRenderer
    private val jobManager = ConcurrentHashMap<String, Long>()
    private val mutex = Mutex()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_tex_js")
        channel.setMethodCallHandler(this)
        renderer = TexRenderer(flutterPluginBinding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "render" -> handleRender(call, result)
            "cancel" -> handleCancel(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        cancel("onDetachedFromEngine")
        renderer.cancel("onDetachedFromEngine")
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
        val fontSize = call.argument<Double>("fontSize")
        if (fontSize == null) {
            result.error("Missing Arg", "Required argument missing", "${call.method} requires 'fontSize'")
            return
        }
        val maxWidth = call.argument<Double>("maxWidth")
        if (maxWidth == null) {
            result.error("Missing Arg", "Required argument missing", "${call.method} requires 'maxWidth'")
            return
        }

        val timestamp = System.nanoTime()
        Log.d("AMK", "Queued $requestId; timestamp=$timestamp")

        val isCancelled: () -> Boolean = {
            val queuedJob = jobManager[requestId]
            val cancelled = queuedJob != timestamp
            if (cancelled) {
                launch(Dispatchers.Main) {
                    result.error("JobCancelled", "The job was cancelled", "Request ID: $requestId")
                }
                mutex.unlock(requestId)
            }
            cancelled
        }

        launch(Dispatchers.Default) {
            Log.d("AMK", "Job $requestId waiting on thread ${Thread.currentThread()}")
            mutex.lock(requestId)
            if (isCancelled()) { return@launch }
            Log.d("AMK", "Job $requestId proceeding to whenReady")
            renderer.render(text, displayMode, color, fontSize, maxWidth) { bytes, error ->
                Log.d("AMK", "Now back from render; job=$requestId; thread=${Thread.currentThread()}")
                if (isCancelled()) { return@render }
                if (bytes != null) {
                    result.success(bytes)
                } else {
                    result.error(error!!.code, error.message, error.details)
                }
                jobManager.remove(requestId, timestamp)
                mutex.unlock(requestId)
            }
        }
        val prev = jobManager.put(requestId, timestamp)
        if (prev != null) {
            Log.d("AMK", "Replaced existing job $requestId")
        }
    }

    private fun handleCancel(call: MethodCall, result: Result) {
        val requestId = call.argument<String>("requestId")
        if (requestId == null) {
            result.error("Missing Arg", "Required argument missing", "${call.method} requires 'requestId'")
            return
        }
        val prev = jobManager.remove(requestId)
        if (prev != null) {
            Log.d("AMK", "Cancelled job $requestId by channel method")
        }
        result.success(null)
    }
}
