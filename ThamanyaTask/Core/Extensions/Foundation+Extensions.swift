//
//  Foundation+Extensions.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - String Extensions
extension String {
    var isNotEmpty: Bool {
        !isEmpty
    }
    
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isValidURL: Bool {
        URL(string: self) != nil
    }
    
    func formatDuration() -> String? {
        guard let duration = Int(self) else { return nil }
        return duration.formatDuration()
    }
}

// MARK: - Int Extensions
extension Int {
    func formatDuration() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return ""
        }
    }
    
    func formatCount() -> String {
        switch self {
        case 0..<1000:
            return "\(self)"
        case 1000..<1_000_000:
            return String(format: "%.1fK", Double(self) / 1000.0)
        case 1_000_000..<1_000_000_000:
            return String(format: "%.1fM", Double(self) / 1_000_000.0)
        default:
            return String(format: "%.1fB", Double(self) / 1_000_000_000.0)
        }
    }
}

// MARK: - Double Extensions
extension Double {
    func formatScore() -> String {
        if self == floor(self) {
            return String(format: "%.0f", self)
        } else {
            return String(format: "%.1f", self)
        }
    }
}

// MARK: - Data Extensions
extension Data {
    var prettyPrintedJSON: String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]) else {
            return nil
        }
        return String(data: prettyData, encoding: .utf8)
    }
    
    var sizeString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(count))
    }
}

// MARK: - URL Extensions
extension URL {
    var isHTTPS: Bool {
        scheme?.lowercased() == "https"
    }
    
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        
        var parameters: [String: String] = [:]
        for item in queryItems {
            parameters[item.name] = item.value
        }
        return parameters
    }
}

// MARK: - Array Extensions
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Result Extensions
extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var isFailure: Bool {
        !isSuccess
    }
    
    var value: Success? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
    
    var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}