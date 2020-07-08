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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch
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
     body { background: transparent; }
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
           setTimeout(sendBounds, 100);
           return true;
       } catch (error) {
           return error.toString();
       }
   }
   function setColor(color) {
       getMathElement().style.color = color;
   }
   function setNoWrap(noWrap) {
       getMathElement().style.whiteSpace = noWrap ? 'nowrap' : 'unset';
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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                WebView.setWebContentsDebuggingEnabled(true)
            }
        }
    }
    private var ready = false
    private var readyListener: ((TexRenderer) -> Unit)? = null
    private var resultListener: ((ByteArray?, TexRenderError?) -> Unit)? = null

    fun whenReady(completionHandler: (TexRenderer) -> Unit) {
        if (ready) {
            completionHandler(this)
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
            listener.invoke(this@TexRenderer)
        }
        readyListener = null
    }

    @JavascriptInterface
    fun takeSnapshot(x: Double, y: Double, width: Double, height: Double) {
        Log.d("AMK", "Taking snapshot of [$x, $y, $width, $height]")
        val bitmap = Bitmap.createBitmap(webView.width, webView.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val listener = resultListener!!
        launch {
            webView.draw(canvas)
            val cropped = Bitmap.createBitmap(bitmap, (x * density).roundToInt(), (y * density).roundToInt(), (width * density).roundToInt(), (height * density).roundToInt())
            val bytes = ByteArrayOutputStream()
            cropped.compress(Bitmap.CompressFormat.PNG, 100, bytes)
            listener.invoke(bytes.toByteArray(), null)
        }
        resultListener = null
    }

    fun render(math: String, displayMode: Boolean, color: String, maxWidth: Double, completionHandler: (ByteArray?, TexRenderError?) -> Unit) {
        val escapedMath = math.replace("\\", "\\\\")
        val js = "setNoWrap(${maxWidth.isInfinite()}); setColor('$color'); render('$escapedMath', $displayMode);"
        Log.d("AMK", "Executing JavaScript: $js")
        setViewWidth(maxWidth)
        resultListener = completionHandler
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            webView.evaluateJavascript(js) {
                if (it != "true") {
                    // failure
                    val err = TexRenderError("RenderError", "An error occurred during rendering", it)
                    completionHandler(null, err)
                }
            }
        } else {
            webView.loadUrl("javascript:$js")
        }
    }

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
