//
//  TexGenerator.swift
//  flutter_tex_js
//
//  Created by Aaron Madlon-Kay on 2020/07/01.
//

import Foundation
import WebKit

@available(iOS 11.0, *)
fileprivate let assetsUrl = Bundle(for: TexRenderer.self).url(forResource: "flutter_tex_js_katex", withExtension: "bundle")!

fileprivate let html = """
<!DOCTYPE html>
<html>
    <head>
        <meta name="viewport" content="width=device-width">
        <link rel="stylesheet" href="katex.min.css">
        <script src="katex.min.js"></script>
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
             return getBounds();
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
     function getBounds() {
         return getMathElement().getBoundingClientRect().toJSON();
     }
     function loadAllFonts() {
         const fontLoadingPromises = [];
         for (const font of document.fonts) {
             fontLoadingPromises.push(font.load());
         }
         Promise.all(fontLoadingPromises).then(function() {
             window.webkit.messageHandlers.ready.postMessage('ready');
         });
     }
     loadAllFonts();
    </script>
</html>
"""

enum TexError : Error {
    case engineError(message: String)
    case executionError
    case pngConversion
    case concurrentRequest
}

@available(iOS 11.0, *)
class TexRenderer : NSObject, WKScriptMessageHandler {

    lazy var webView = initWebView()
    var ready = false
    var readyListener : (() -> Void)?
    var busy = false

    private func initWebView() -> WKWebView {
        let controller = WKUserContentController()
        controller.add(self, name: "ready")
        controller.add(self, name: "debug")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: config)
        webView.isOpaque = false
        return webView
    }

    private func whenReady(_ completionHandler: @escaping () -> Void) {
        if ready {
            completionHandler()
        } else {
            readyListener = completionHandler
            webView.loadHTMLString(html, baseURL: assetsUrl)
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "ready":
            ready = true
            readyListener?()
            readyListener = nil
        default:
            debugPrint("Message from WebView to: \(message.name); body: \(message.body)")
        }
    }

    func render(_ math: String, displayMode: Bool, color: String, maxWidth: Double, completionHandler: @escaping (Data?, Error?) -> Void) {
        whenReady { [weak self] in
            guard let self = self else {
                return
            }
            guard !self.busy else {
                completionHandler(nil, TexError.concurrentRequest)
                return
            }
            self.setFrameWidth(maxWidth)
            let escapedMath = math.replacingOccurrences(of: "\\", with: "\\\\")
            let js = "setNoWrap(\(maxWidth.isInfinite)); setColor('\(color)'); render('\(escapedMath)', \(displayMode));"
            log("Executing JavaScript: \(js)")
            self.busy = true
            self.webView.evaluateJavaScript(js) { [weak self] result, error in
                guard let self = self else {
                    return
                }
                if let result = result as? [String:Any] {
                    // Success
                    self.takeSnapshot(result, completionHandler)
                } else if let result = result as? String {
                    // Engine error
                    completionHandler(nil, TexError.engineError(message: result))
                } else {
                    // Other error
                    completionHandler(nil, TexError.executionError)
                }
                self.busy = false
            }
        }
    }

    private func setFrameWidth(_ newWidth: Double) {
        let frameWidth = newWidth.isFinite ? newWidth : Double(UIScreen.main.bounds.width)
        let newFrame = CGRect(x: 0, y: 0, width: Int(frameWidth.rounded(.down)), height: Int(webView.frame.height))
        if webView.frame != newFrame {
            log("New frame width: \(frameWidth); was \(webView.frame.width)")
            webView.frame = newFrame
        }
    }

    private func takeSnapshot(_ bbox: [String:Any], _ completionHandler: @escaping (Data?, Error?) -> Void) {
        let x = (bbox["left"] as! NSNumber).intValue
        let y = (bbox["top"] as! NSNumber).intValue
        let w = (bbox["width"] as! NSNumber).intValue
        let h = (bbox["height"] as! NSNumber).intValue
        let rect = CGRect(x: x, y: y, width: w, height: h)
        log("Taking snapshot of \(rect)")

        let snapConfig = WKSnapshotConfiguration()
        snapConfig.rect = rect
        if #available(iOS 13.0, *) {
            snapConfig.afterScreenUpdates = true
        }
        webView.takeSnapshot(with: snapConfig) { image, error in
            guard let image = image else {
                completionHandler(nil, error)
                return
            }
            guard let data = image.pngData() else {
                completionHandler(nil, TexError.pngConversion)
                return
            }
            completionHandler(data, nil)
        }
    }
}
