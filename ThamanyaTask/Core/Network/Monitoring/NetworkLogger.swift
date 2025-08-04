//
//  NetworkLogger.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
import OSLog

// MARK: - Log Level
public enum LogLevel: Int, CaseIterable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    
    public var emoji: String {
        switch self {
        case .verbose: return "💬"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    public var name: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
}

// MARK: - Log Event
public enum LogEvent {
    case request(URLRequest)
    case response(data: Data, model: String? = nil)
    case error(NetworkError)
    case info(String)
    case warning(String)
    case debug(String)
    case verbose(String)
    
    public var level: LogLevel {
        switch self {
        case .request, .response: return .info
        case .error: return .error
        case .info: return .info
        case .warning: return .warning
        case .debug: return .debug
        case .verbose: return .verbose
        }
    }
}

// MARK: - Network Logger Protocol
public protocol NetworkLogging {
    func log(_ event: LogEvent) async
    func setLogLevel(_ level: LogLevel)
}

// MARK: - Network Logger Implementation
public final class NetworkLogger: NetworkLogging {
    
    // MARK: - Properties
    private let osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ThamanyaTask", category: "Network")
    private var currentLogLevel: LogLevel = .debug
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "network.logger", qos: .utility)
    
    // MARK: - Initialization
    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    // MARK: - Public Methods
    public func log(_ event: LogEvent) async {
        guard event.level.rawValue >= currentLogLevel.rawValue else { return }
        
        await withCheckedContinuation { continuation in
            queue.async {
                self.performLogging(event)
                continuation.resume()
            }
        }
    }
    
    public func setLogLevel(_ level: LogLevel) {
        currentLogLevel = level
    }
    
    // MARK: - Private Methods
    private func performLogging(_ event: LogEvent) {
        let timestamp = dateFormatter.string(from: Date())
        let level = event.level
        let prefix = "\(level.emoji) [\(level.name)] \(timestamp)"
        
        switch event {
        case .request(let urlRequest):
            logRequest(urlRequest, prefix: prefix)
        case .response(let data, let model):
            logResponse(data, model: model, prefix: prefix)
        case .error(let networkError):
            logError(networkError, prefix: prefix)
        case .info(let message):
            logMessage(message, prefix: prefix, level: .info)
        case .warning(let message):
            logMessage(message, prefix: prefix, level: .warning)
        case .debug(let message):
            logMessage(message, prefix: prefix, level: .debug)
        case .verbose(let message):
            logMessage(message, prefix: prefix, level: .verbose)
        }
    }
    
    private func logRequest(_ request: URLRequest, prefix: String) {
        var logString = "\(prefix) REQUEST:\n"
        logString += "📡 \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "Unknown URL")\n"
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logString += "📋 Headers:\n"
            for (key, value) in headers {
                logString += "   \(key): \(value)\n"
            }
        }
        
        if let body = request.httpBody {
            logString += "📦 Body (\(body.count) bytes):\n"
            if let bodyString = String(data: body, encoding: .utf8) {
                logString += "   \(bodyString)\n"
            } else {
                logString += "   [Binary Data]\n"
            }
        }
        
        osLogger.info("\(logString)")
    }
    
    private func logResponse(_ data: Data, model: String?, prefix: String) {
        var logString = "\(prefix) RESPONSE:\n"
        logString += "📦 Size: \(data.count) bytes\n"
        
        if let model = model {
            logString += "🏗️ Model: \(model)\n"
        }
        
        if currentLogLevel == .verbose {
            if let responseString = String(data: data, encoding: .utf8) {
                logString += "📄 Content:\n\(responseString)\n"
            } else {
                logString += "📄 Content: [Binary Data]\n"
            }
        }
        
        osLogger.info("\(logString)")
    }
    
    private func logError(_ error: NetworkError, prefix: String) {
        let logString = "\(prefix) ERROR:\n💥 \(error.localizedDescription) (Code: \(error.errorCode))"
        osLogger.error("\(logString)")
    }
    
    private func logMessage(_ message: String, prefix: String, level: LogLevel) {
        let logString = "\(prefix) \(message)"
        
        switch level {
        case .verbose, .debug, .info:
            osLogger.info("\(logString)")
        case .warning:
            osLogger.warning("\(logString)")
        case .error:
            osLogger.error("\(logString)")
        }
    }
}