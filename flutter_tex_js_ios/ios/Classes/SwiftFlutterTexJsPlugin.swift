import Flutter
import UIKit

func log(_ message: String) {
    #if DEBUG
        print(message)
    #endif
}

public class SwiftFlutterTexJsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_tex_js", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterTexJsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    lazy var renderer = TexRenderer()

    let queue = DispatchQueue(label: "TexJsRenderQueue", qos: .userInteractive)
    let semaphore = DispatchSemaphore(value: 1)
    let jobManager = ConcurrentDictionary<String, Double>()

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "render":
            handleRender(call, result)
        case "cancel":
            handleCancel(call, result)
        default:
            result(FlutterError(code: "UnsupportedMethod", message: "\(call.method) is not supported", details: nil))
        }
    }

    func handleRender(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String:Any?] else {
            result(FlutterError(code: "MissingArgs", message: "Required arguments missing", details: "\(call.method) requires 'requestId', 'text', 'displayMode', 'color', 'fontSize', 'maxWidth'"))
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
        guard let fontSize = args["fontSize"] as? Double else {
            result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'fontSize'"))
            return
        }
        guard let maxWidth = args["maxWidth"] as? Double else {
            result(FlutterError(code: "MissingArg", message: "Required argument missing", details: "\(call.method) requires 'maxWidth'"))
            return
        }

        log("New request: \(args)")

        let timestamp = NSDate().timeIntervalSinceReferenceDate

        let isCancelled = { [weak self] () -> Bool in
            let queuedJob = self?.jobManager.get(requestId)
            let cancelled = timestamp != queuedJob
            if cancelled {
                log("Job \(requestId) canceled! Exiting")
                result(FlutterError(code: "JobCancelled", message: "The job was cancelled", details: "Request ID: \(requestId)"))
                self?.semaphore.signal()
                log("Remaining jobs: \(self?.jobManager.count ?? -1)")
            }
            return cancelled
        }

        queue.async { [weak self] in
            log("Job \(requestId) waiting")
            self?.semaphore.wait()
            guard !isCancelled() else { return }

            // WebView init has to be done on UI thread
            DispatchQueue.main.async {
                log("Now on main thread; job=\(requestId)")
                guard !isCancelled() else { return }
                let start = NSDate().timeIntervalSinceReferenceDate

                log("Going to render; job=\(requestId)")
                self?.renderer.render(text, displayMode: displayMode, color: color, fontSize: fontSize, maxWidth: maxWidth) { data, error in
                    log("Now back from render; job=\(requestId)")
                    guard !isCancelled() else { return }

                    let end = NSDate().timeIntervalSinceReferenceDate
                    log("Rendering job \(requestId) took \(Int((end - timestamp) * 1000)) ms (\(Int((end - start) * 1000)) rendering; \(Int((start - timestamp) * 1000)) queued)")

                    if let data = data {
                        result(FlutterStandardTypedData(bytes: data))
                    } else {
                        result(FlutterError(code: "RenderError", message: "An error occurred during rendering", details: "\(error!)"))
                    }

                    log("Job \(requestId) complete")
                    self?.jobManager.remove(key: requestId, value: timestamp)
                    self?.semaphore.signal()
                }
            }
        }

        log("Queueing job \(requestId)")
        let prev = jobManager.put(key: requestId, value: timestamp)
        if prev != nil {
            log("Replaced existing job \(requestId)")
        }
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
            log("Cancelled job \(requestId) by channel method")
            log("Remaining jobs: \(jobManager.count)")
        }
        result(nil)
    }
}

class ConcurrentDictionary<K: Hashable,V: Equatable> {
    var data: [K:V] = [:]
    let lock = NSLock()

    @discardableResult
    func put(key: K, value: V?) -> V? {
        lock.lock()
        defer { lock.unlock() }
        let prev = data[key]
        data[key] = value
        return prev
    }

    @discardableResult
    func remove(_ key: K) -> V? {
        lock.lock()
        defer { lock.unlock() }
        return data.removeValue(forKey: key)
    }

    @discardableResult
    func remove(key: K, value: V?) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if data[key] == value {
            data.removeValue(forKey: key)
            return true
        }
        return false
    }

    func get(_ key: K) -> V? {
        lock.lock()
        defer { lock.unlock() }
        return data[key]
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return data.count
    }
}
