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
           sendBounds();
           return true;
       } catch (error) {
           return error.toString();
       }
   }
   function setColor(color) {
       getMathElement().style.color = color;
   }
   function sendBounds() {
       const bounds = getMathElement().getBoundingClientRect().toJSON();
       window.webkit.messageHandlers.result.postMessage(bounds);
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

class TexRenderer : NSObject, WKScriptMessageHandler {

    lazy var webView = initWebView()
    var ready = false
    var readyListener : ((TexRenderer) -> Void)?
    var resultListener : ((Data?, Error?) -> Void)?
    
    private func initWebView() -> WKWebView {
        let controller = WKUserContentController()
        controller.add(self, name: "ready")
        controller.add(self, name: "result")
        controller.add(self, name: "debug")
        
        let config = WKWebViewConfiguration()
        config.userContentController = controller

        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: config)
        webView.isOpaque = false
        return webView
    }
    
    func whenReady(_ completionHandler: @escaping (TexRenderer) -> Void) {
        if ready {
            completionHandler(self)
        } else {
            readyListener = completionHandler
            webView.loadHTMLString(html, baseURL: assetsUrl)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "ready":
            ready = true
            readyListener?(self)
            readyListener = nil
        case "result":
            if let resultListener = resultListener,
                let bounds = message.body as? [String:Any] {
                takeSnapshot(bounds, resultListener)
                self.resultListener = nil
            }
        default:
            print("Message from WebView to: \(message.name); body: \(message.body)")
        }
    }

    func render(_ math: String, displayMode: Bool, color: String, completionHandler: @escaping (Data?, Error?) -> Void) {
        guard resultListener == nil else {
            completionHandler(nil, TexError.concurrentRequest)
            return
        }
        let escapedMath = math.replacingOccurrences(of: "\\", with: "\\\\")
        let js = "setColor('\(color)'); render('\(escapedMath)', \(displayMode))"
        resultListener = completionHandler
        webView.evaluateJavaScript(js) { result, error in
            if result as? Bool == true {
                // Success
                return
            }
            // Failure
            if let result = result as? String {
                completionHandler(nil, TexError.engineError(message: result))
            } else {
                completionHandler(nil, TexError.executionError)
            }
            self.resultListener = nil
        }
    }

    private func takeSnapshot(_ bbox: [String:Any], _ completionHandler: @escaping (Data?, Error?) -> Void) {
        let x = (bbox["left"] as! NSNumber).intValue
        let y = (bbox["top"] as! NSNumber).intValue
        let w = (bbox["width"] as! NSNumber).intValue
        let h = (bbox["height"] as! NSNumber).intValue
        let rect = CGRect(x: x, y: y, width: w, height: h)
        let snapConfig = WKSnapshotConfiguration()
        snapConfig.rect = rect
        if #available(iOS 13.0, *) {
            snapConfig.afterScreenUpdates = true
        }
        self.webView.takeSnapshot(with: snapConfig) { image, error in
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
