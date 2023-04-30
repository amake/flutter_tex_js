package com.madlonkay.flutter_tex_js

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.os.Build
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebView
import androidx.annotation.MainThread
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import kotlin.math.max
import kotlin.math.roundToInt

private const val html = """
<!DOCTYPE html>
<html id="root">
    <head>
        <!-- Viewport settings perhaps not needed on Android -->
        <meta name="viewport" content="initial-scale=1, maximum-scale=1, minimum-scale=1">
        <link rel="stylesheet" href="katex/katex.min.css">
        <script src="katex/katex.min.js"></script>
        <style type="text/css">
         body { background: transparent; margin: 0; }
         .katex-display { margin: 0; }
         .katex-html > .tag { position: unset !important; padding-left: 2em; }
         #math { float: left; }
        </style>
    </head>
    <body>
        <span id="math"></span>
    </body>
    <script>
     function getContainer() {
         return document.getElementById('math');
     }
     function render(math, displayMode) {
         try {
             katex.render(math, getContainer(), {
                 output: 'html',
                 displayMode: displayMode
             });
             // Returning immediately or setting 0 timeout here yielded bad results (incomplete
             // rendering, that weird zooming thing)
             const now = Date.now();
             setTimeout(function() { sendBounds(now); }, 100);
             return true;
         } catch (error) {
             sendError(error);
             return false;
         }
     }
     function setColor(color) {
         getContainer().style.color = color;
     }
     function setFontSize(fontSize) {
         getContainer().style.fontSize = fontSize;
     }
     function setNoWrap(noWrap) {
         getContainer().style.whiteSpace = noWrap ? 'nowrap' : 'unset';
     }
     function setWidth(width) {
         document.getElementById('root').style.width = width;
     }
     function sendError(error) {
         TexRenderer.onError(error.toString());
     }
     function sendBounds(timestamp) {
         const bounds = getContainer().getBoundingClientRect();
         TexRenderer.takeSnapshot(bounds.x, bounds.y, bounds.width, bounds.height, timestamp);
     }
     function loadAllFonts() {
         const fontLoadingPromises = [];
         for (const font of document.fonts) {
             fontLoadingPromises.push(font.load());
         }
         Promise.all(fontLoadingPromises).then(function() {
             TexRenderer.onReady();
         });
     }
     loadAllFonts();
    </script>
</html>
"""

@SuppressLint("SetJavaScriptEnabled", "AddJavascriptInterface")
class TexRenderer(private val context: Context) : CoroutineScope by MainScope() {

    private val density get() = context.resources.displayMetrics.density
    private val webView: WebView by lazy {
        WebView(context).apply {
            settings.javaScriptEnabled = true
            addJavascriptInterface(this@TexRenderer, "TexRenderer")
            // Size cannot be 0x0, but 1x1 works
            layout(0, 0, 1, 1)
            setBackgroundColor(Color.TRANSPARENT)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                setRendererPriorityPolicy(WebView.RENDERER_PRIORITY_IMPORTANT, false)
            }
        }
    }
    private var ready = false
    private var readyListener: (suspend () -> Unit)? = null
    private var resultListener: ((ByteArray?, TexRenderError?) -> Unit)? = null
    private var previousJs: String? = null
    private var previousBytes: ByteArray? = null

    init {
        if (BuildConfig.DEBUG && Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            WebView.setWebContentsDebuggingEnabled(true)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            WebView.enableSlowWholeDocumentDraw()
        }
    }

    @MainThread
    private suspend fun whenReady(completionHandler: suspend () -> Unit) = withContext(Dispatchers.Main) {
        if (ready) {
            completionHandler()
        } else {
            readyListener = completionHandler
            webView.loadDataWithBaseURL("file:///android_asset/", html, "text/html", null, null)
        }
    }

    @JavascriptInterface
    fun onReady() {
        Log.d("AMK", "onReady called; thread=${Thread.currentThread()}")
        ready = true
        val listener = readyListener!!
        launch {
            listener.invoke()
        }
        readyListener = null
    }

    @JavascriptInterface
    fun onError(error: String) {
        Log.d("AMK", "onError called; thread=${Thread.currentThread()}")
        val listener = resultListener!!
        launch {
            val err = TexRenderError("RenderError", "An error occurred during rendering", error)
            listener(null, err)
        }
        resultListener = null
        previousJs = null
        previousBytes = null
    }

    @JavascriptInterface
    fun takeSnapshot(x: Double, y: Double, width: Double, height: Double, timestamp: Double) {
        val xPx = (x * density).roundToInt()
        val yPx = (y * density).roundToInt()
        val widthPx = max((width * density).roundToInt(), 1)
        val heightPx = max((height * density).roundToInt(), 1)
        Log.d("AMK", "Taking snapshot of [$x, $y, $width, $height], scaled to [$xPx, $yPx, $widthPx, $heightPx]")
        val listener = resultListener!!
        launch {
            var byteArray: ByteArray? = null
            for (i in 0..100) {
                byteArray = getSnapshotBytes(xPx, yPx, widthPx, heightPx)
                if (byteArray.contentEquals(previousBytes)) {
                    // Log.d("AMK", "bytes were the same! delaying")
                    delay(50L)
                } else {
                    Log.d("AMK", "bytes look correct; took ${System.currentTimeMillis() - timestamp}ms over $i retries")
                    break
                }
            }
            previousBytes = byteArray
            listener.invoke(byteArray, null)
        }
        resultListener = null
    }

    private fun getSnapshotBytes(xPx: Int, yPx: Int, widthPx: Int, heightPx: Int): ByteArray {
        // val start = System.currentTimeMillis()
        val bitmap = Bitmap.createBitmap(xPx + widthPx, yPx + heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        webView.draw(canvas)
        val clipped = if (xPx != 0 || yPx != 0) {
            Bitmap.createBitmap(bitmap, xPx, yPx, widthPx, heightPx)
        } else {
            bitmap
        }
        val byteStream = ByteArrayOutputStream()
        clipped.compress(Bitmap.CompressFormat.PNG, 100, byteStream)
        val byteArray = byteStream.toByteArray()
        bitmap.recycle()
        clipped.recycle()
        // Log.d("AMK", "generating bytes took ${System.currentTimeMillis() - start}ms")
        return byteArray
    }

    @MainThread
    suspend fun render(math: String, displayMode: Boolean, color: String, fontSize: Double, maxWidth: Double, completionHandler: (ByteArray?, TexRenderError?) -> Unit) = withContext(Dispatchers.Main) {
        whenReady {
            if (resultListener != null) {
                val err = TexRenderError("ConcurrencyError", "A render job was already in progress", null)
                completionHandler(null, err)
                return@whenReady
            }
            val noWrap = maxWidth.isInfinite()
            val newWidth = if (noWrap) {
                "unset"
            } else {
                "${maxWidth}px"
            }
            val js = "setNoWrap($noWrap); setWidth('$newWidth'); setColor('$color'); setFontSize('${fontSize}px'); render('$math', $displayMode);"
            Log.d("AMK", "Executing JavaScript: $js")
            if (previousJs == js && previousBytes != null) {
                completionHandler.invoke(previousBytes!!, null)
            } else {
                resultListener = completionHandler
                previousJs = js
                // We call loadUrl instead of evaluateJavascript for backwards compatibility, and
                // because we can't really make use of the immediately returned result
                webView.loadUrl("javascript:$js")
            }
        }
    }
}

data class TexRenderError(val code: String, val message: String?, val details: String?)
