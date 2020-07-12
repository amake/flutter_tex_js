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
import kotlin.math.roundToInt

private const val html =
"""
<!DOCTYPE html>
<html>
    <head>
        <meta name="viewport" content="width=device-width">
        <link rel="stylesheet" href="katex/katex.min.css">
        <script src="katex/katex.min.js"></script>
        <style type="text/css">
         body { background: transparent; margin: 0; }
         #math { float: left; }
        </style>
    </head>
    <body>
        <span id="math"></span>
    </body>
    <script>
     function getMathElement() {
         return document.getElementById('math');
     }
     function render(math, displayMode) {
         try {
             katex.render(math, getMathElement(), {
                 output: 'html',
                 displayMode: displayMode
             });
             // Returning immediately or setting 0 timeout here yielded bad results (incomplete
             // rendering, that weird zooming thing)
             setTimeout(sendBounds, 100);
             return true;
         } catch (error) {
             sendError(error);
             return false;
         }
     }
     function setColor(color) {
         getMathElement().style.color = color;
     }
     function setNoWrap(noWrap) {
         getMathElement().style.whiteSpace = noWrap ? 'nowrap' : 'unset';
     }
     function sendError(error) {
         TexRenderer.onError(error.toString());
     }
     function sendBounds() {
         const bounds = getMathElement().getBoundingClientRect();
         TexRenderer.takeSnapshot(bounds.x, bounds.y, bounds.width, bounds.height);
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
            val metrics = context.resources.displayMetrics
            layout(0, 0, metrics.widthPixels, metrics.heightPixels)
            setBackgroundColor(Color.TRANSPARENT)
        }
    }
    private var ready = false
    private var readyListener: (suspend () -> Unit)? = null
    private var resultListener: ((ByteArray?, TexRenderError?) -> Unit)? = null

    @MainThread
    private suspend fun whenReady(completionHandler: suspend () -> Unit) = withContext(Dispatchers.Main) {
        if (ready) {
            completionHandler()
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                WebView.setWebContentsDebuggingEnabled(true)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                WebView.enableSlowWholeDocumentDraw()
            }
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
    }

    @JavascriptInterface
    fun takeSnapshot(x: Double, y: Double, width: Double, height: Double) {
        val xPx = (x * density).roundToInt()
        val yPx = (y * density).roundToInt()
        val widthPx = (width * density).roundToInt()
        val heightPx = (height * density).roundToInt()
        Log.d("AMK", "Taking snapshot of [$x, $y, $width, $height], scaled to [$xPx, $yPx, $widthPx, $heightPx]")
        var bitmap = Bitmap.createBitmap(xPx + widthPx, yPx + heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val listener = resultListener!!
        launch {
            webView.draw(canvas)
            if (xPx != 0 || yPx != 0) {
                bitmap = Bitmap.createBitmap(bitmap, xPx, yPx, widthPx, heightPx)
            }
            val bytes = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes)
            listener.invoke(bytes.toByteArray(), null)
        }
        resultListener = null
    }

    @MainThread
    suspend fun render(math: String, displayMode: Boolean, color: String, maxWidth: Double, completionHandler: (ByteArray?, TexRenderError?) -> Unit) = withContext(Dispatchers.Main) {
        whenReady {
            if (resultListener != null) {
                val err = TexRenderError("ConcurrencyError", "A render job was already in progress", null)
                completionHandler(null, err)
                return@whenReady
            }
            resultListener = completionHandler
            val js = "setNoWrap(${maxWidth.isInfinite()}); setColor('$color'); render('$math', $displayMode);"
            Log.d("AMK", "Executing JavaScript: $js")
            setViewWidth(maxWidth)
            // We call loadUrl instead of evaluateJavascript for backwards compatibility, and
            // because we can't really make use of the immediately returned result
            webView.loadUrl("javascript:$js")
        }
    }

    @MainThread
    private fun setViewWidth(width: Double) {
        val newWidth = if (width.isFinite()) {
            (width * density).roundToInt()
        } else {
            context.resources.displayMetrics.widthPixels
        }
        if (webView.width != newWidth) {
            Log.d("AMK", "New frame width: $newWidth; was ${webView.width}")
            webView.layout(0, 0, newWidth, webView.height)
        }
    }
}

data class TexRenderError(val code: String, val message: String?, val details: String?)
