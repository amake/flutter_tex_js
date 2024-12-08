//
//  TexGenerator.swift
//  flutter_tex_js
//
//  Created by Aaron Madlon-Kay on 2020/07/01.
//

import Foundation
import WebKit

fileprivate let assetsUrl = Bundle(for: TexRenderer.self).url(forResource: "flutter_tex_js_katex", withExtension: "bundle")!

fileprivate let html = """
<!DOCTYPE html>
<html id="root">
    <head>
        <meta name="viewport" content="initial-scale=1, maximum-scale=1, minimum-scale=1">
        <link rel="stylesheet" href="katex.min.css">
        <script src="katex.min.js"></script>
        <style type="text/css">
         body { background: transparent; margin: 0; }
         .katex-display { margin: 0; padding: 1px 0; }
         .katex-html > .tag { position: unset !important; padding-left: 2em; }
         #math { float: left; padding-top: 1px; padding-bottom: 1px; }
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
             return getBounds();
         } catch (error) {
             return error.toString();
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
     function getBounds() {
         return getContainer().getBoundingClientRect().toJSON();
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
    case executionError(message: String)
    case pngConversion
    case concurrentRequest
}

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

        let webView = WKWebView(frame: .zero, configuration: config)
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

    func render(_ math: String, displayMode: Bool, color: String, fontSize: Double, maxWidth: Double, completionHandler: @escaping (Data?, Error?) -> Void) {
        whenReady { [weak self] in
            guard let self = self else {
                return
            }
            guard !self.busy else {
                completionHandler(nil, TexError.concurrentRequest)
                return
            }
            self.busy = true
            let noWrap = maxWidth.isInfinite
            let newWidth: String
            if noWrap {
                newWidth = "unset"
            } else {
                newWidth = "\(maxWidth)px"
            }
            let js = "setNoWrap(\(noWrap)); setWidth('\(newWidth)'); setColor('\(color)'); setFontSize('\(fontSize)px'); render('\(math)', \(displayMode));"
            log("Executing JavaScript: \(js)")
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
                } else if let result = result {
                    // Other error
                    completionHandler(nil, TexError.executionError(message: "\(result)"))
                } else {
                    completionHandler(nil, error)
                }
                self.busy = false
            }
        }
    }

    private func takeSnapshot(_ bbox: [String:Any], _ completionHandler: @escaping (Data?, Error?) -> Void) {
        let x = (bbox["left"] as! NSNumber).intValue
        let y = (bbox["top"] as! NSNumber).intValue
        let w = max((bbox["width"] as! NSNumber).intValue, 1)
        let h = max((bbox["height"] as! NSNumber).intValue, 1)
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
