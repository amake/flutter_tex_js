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

    let queue = DispatchQueue(label: "TexJsRenderQueue", qos: .userInteractive)
    let semaphore = DispatchSemaphore(value: 1)
    let jobManager = ConcurrentDictionary<DispatchWorkItem>()

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "render":
            if #available(iOS 11.0, *) {
                handleRender(call, result)
            } else {
                result(FlutterError(code: "UnsupportedOsVersion", message: "iOS 11+ is required", details: nil))
            }
        case "cancel":
            handleCancel(call, result)
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
        guard let maxWidth = args["maxWidth"] as? Double else {
            result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'maxWidth'"))
            return
        }

//        debugPrint("New request: \(args)")

//        let queued = NSDate().timeIntervalSinceReferenceDate * 1000

        // Set up job; see
        // https://stackoverflow.com/a/38372384/448068

        var job: DispatchWorkItem?

        let cleanup = { [weak self] in
            job = nil
            self?.semaphore.signal()
//            debugPrint("Remaining jobs: \(self?.jobManager.count ?? -1)")
        }

        let isCancelled = { [weak self] () -> Bool in
            let queuedJob = self?.jobManager.get(requestId)
            let cancelled = queuedJob == nil || job! !== queuedJob!
            if cancelled {
//                debugPrint("Job \(requestId) canceled! Exiting")
                result(FlutterError(code: "JobCancelled", message: "The job was cancelled", details: "Request ID: \(requestId)"))
                cleanup()
            }
            return cancelled
        }

        job = DispatchWorkItem { [weak self] in
//            debugPrint("Job \(requestId) waiting")
            self?.semaphore.wait()
            guard !isCancelled() else { return }

            // WebView init has to be done on UI thread
            DispatchQueue.main.async {
//                debugPrint("Now on main thread; job=\(requestId)")
                guard !isCancelled() else { return }
//                    let start = NSDate().timeIntervalSinceReferenceDate * 1000

//                    debugPrint("Going to render; job=\(requestId)")
                self?.renderer.render(text, displayMode: displayMode, color: color, maxWidth: maxWidth) { data, error in
//                        debugPrint("Now back from render; job=\(requestId)")
                    guard !isCancelled() else { return }

//                        let end = NSDate().timeIntervalSinceReferenceDate * 1000
//                        debugPrint("Rendering job \(requestId) took \(Int(end - queued)) ms (\(Int(end - start)) rendering; \(Int(start - queued)) queued)")

                    if let data = data {
                        result(FlutterStandardTypedData(bytes: data))
                    } else {
                        result(FlutterError(code: "RenderError", message: "An error occurred during rendering", details: "\(error!)"))
                    }

//                        debugPrint("Job \(requestId) complete")
                    self?.jobManager.mapItem(key: requestId) { prev in
                        if prev == nil || prev! === job! {
                            return nil
                        } else {
                            return prev
                        }
                    }
                    cleanup()
                }
            }
        }

//        debugPrint("Queueing job \(requestId)")
        if jobManager.put(key: requestId, value: job) != nil {
//            debugPrint("Replaced existing job \(requestId)")
        }
        queue.async(execute: job!)
    }

    func handleCancel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String:Any?] else {
            result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'requestId', 'text', 'displayMode', 'color'"))
            return
        }
        guard let requestId = args["requestId"] as? String else {
            result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'requestId'"))
            return
        }
        if jobManager.remove(requestId) != nil {
//            debugPrint("Cancelled job \(requestId) by channel method")
//            debugPrint("Remaining jobs: \(jobManager.count)")
        }
        result(nil)
    }
}

class ConcurrentDictionary<T> {
    var data: [String:T] = [:]
    let queue = DispatchQueue(label: "ConcurrentDictionaryQueue")

    private var readData: [String:T] {
        var data: [String:T]!
        queue.sync {
            data = self.data
        }
        return data
    }

    @discardableResult
    func put(key: String, value: T?) -> T? {
        mapItem(key: key) { prev in
            value
        }
    }

    @discardableResult
    func mapItem(key: String, block: @escaping (T?) -> T?) -> T? {
        var previous: T?
        queue.sync(flags: .barrier) {
            previous = self.data[key]
            self.data[key] = block(previous)
        }
        return previous
    }

    @discardableResult
    func remove(_ key: String) -> T? {
        return put(key: key, value: nil)
    }

    func get(_ key: String) -> T? {
        readData[key]
    }

    var count: Int {
        readData.count
    }
}
