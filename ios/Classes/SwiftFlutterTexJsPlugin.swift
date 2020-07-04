import Flutter
import UIKit

public class SwiftFlutterTexJsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_tex_js", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterTexJsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    @available(iOS 11.0, *)
    lazy var renderer = TexRenderer()

    let queue = DispatchQueue(label: "TexJsRenderQueue", qos: .userInteractive, attributes: .concurrent)
    let semaphore = DispatchSemaphore(value: 1)
    var jobs: [String:DispatchWorkItem] = [:]

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "render":
            if #available(iOS 11.0, *) {
                handleRender(call, result)
            } else {
                result(FlutterError(code: "UnsupportedOsVersion", message: "iOS 11+ is required", details: nil))
            }
        default:
            result(FlutterError(code: "UnsupportedMethod", message: "\(call.method) is not supported", details: nil))
        }
    }

    @available(iOS 11.0, *)
    func handleRender(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String:Any?] else {
            result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'requestId', 'text', 'displayMode', 'color'"))
            return
        }
        guard let requestId = args["requestId"] as? String else {
            result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'requestId'"))
            return
        }
        guard let text = args["text"] as? String else {
            result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'text'"))
            return
        }
        guard let displayMode = args["displayMode"] as? Bool else {
            result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'displayMode'"))
            return
        }
        guard let color = args["color"] as? String else {
            result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'color'"))
            return
        }
        let queued = NSDate().timeIntervalSinceReferenceDate * 1000

        // Set up job; see
        // https://stackoverflow.com/a/38372384/448068

        var job: DispatchWorkItem?

        let cleanup = { [weak self] in
            job = nil
            self?.jobs[requestId] = nil
            self?.semaphore.signal()
        }

        let isCancelled = { () -> Bool in
            if job?.isCancelled ?? true {
                debugPrint("Job \(requestId) canceled! Exiting")
                result(FlutterError(code: "JobCancelled", message: "The job was cancelled", details: "Request ID: \(requestId)"))
                cleanup()
                return true
            } else {
                return false
            }
        }

        job = DispatchWorkItem { [weak self] in
            self?.semaphore.wait()
            guard !isCancelled() else { return }
            // WebView init has to be done on UI thread
            DispatchQueue.main.async {
                guard !isCancelled() else { return }
                self?.renderer.whenReady { renderer in
                    guard !isCancelled() else { return }
                    let start = NSDate().timeIntervalSinceReferenceDate * 1000
                    renderer.render(text, displayMode: displayMode, color: color) { data, error in
                        let end = NSDate().timeIntervalSinceReferenceDate * 1000
                        debugPrint("Rendering \(text) took \(Int(end - queued)) ms (\(Int(end - start)) rendering; \(Int(start - queued)) queued)")
                        if let data = data {
                            result(FlutterStandardTypedData(bytes: data))
                        } else {
                            result(FlutterError(code: "RenderError", message: "An error occurred during rendering", details: "\(error!)"))
                        }
                        debugPrint("Job \(requestId) complete")
                        cleanup()
                    }
                }
            }
        }

        if let existingJob = jobs[requestId] {
            debugPrint("Canceling existing job \(requestId)")
            existingJob.cancel()
        }

        debugPrint("Queueing job \(requestId)")
        jobs[requestId] = job
        queue.async(execute: job!)
    }
}
