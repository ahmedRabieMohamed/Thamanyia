//
//  NetworkCache.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - Cache Policy
public enum CachePolicy: Sendable {
    case none
    case memoryOnly
    case diskOnly
    case memoryAndDisk
    case automatic
}

// MARK: - Cache Entry
public final class CacheEntry: @unchecked Sendable {
    let data: Data
    let timestamp: Date
    let expirationDate: Date
    let etag: String?
    let size: Int
    
    public var isExpired: Bool {
        Date() > expirationDate
    }
    
    public init(data: Data, expirationInterval: TimeInterval = 300, etag: String? = nil) {
        self.data = data
        self.timestamp = Date()
        self.expirationDate = Date().addingTimeInterval(expirationInterval)
        self.etag = etag
        self.size = data.count
    }
    
    private init(data: Data, timestamp: Date, expirationDate: Date, etag: String?, size: Int) {
        self.data = data
        self.timestamp = timestamp
        self.expirationDate = expirationDate
        self.etag = etag
        self.size = size
    }
    
    static func create(data: Data, timestamp: Date, expirationDate: Date, etag: String?) -> CacheEntry {
        return CacheEntry(data: data, timestamp: timestamp, expirationDate: expirationDate, etag: etag, size: data.count)
    }
}

// MARK: - Network Cache Protocol
public protocol NetworkCaching {
    func store(data: Data, for request: URLRequest, policy: CachePolicy) async
    func retrieve(for request: URLRequest) async -> CacheEntry?
    func remove(for request: URLRequest) async
    func clearAll() async
    func clearExpired() async
    func getCacheSize() async -> Int
    func getCacheInfo() async -> CacheInfo
}

// MARK: - Cache Info
public struct CacheInfo {
    let totalSize: Int
    let entryCount: Int
    let oldestEntry: Date?
    let newestEntry: Date?
    let expiredCount: Int
}

// MARK: - Network Cache Implementation
public final class NetworkCache: NetworkCaching {
    
    // MARK: - Properties
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let queue = DispatchQueue(label: "network.cache", qos: .utility)
    private let maxMemorySize: Int
    private let maxDiskSize: Int
    private var currentDiskSize: Int = 0
    
    // MARK: - Initialization
    public init(maxMemorySize: Int = 50 * 1024 * 1024, maxDiskSize: Int = 100 * 1024 * 1024) {
        self.maxMemorySize = maxMemorySize
        self.maxDiskSize = maxDiskSize
        
        // Setup cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cacheDir.appendingPathComponent("NetworkCache")
        
        setupCache()
    }
    
    // MARK: - Public Methods
    public func store(data: Data, for request: URLRequest, policy: CachePolicy = .automatic) async {
        let key = generateCacheKey(for: request)
        let entry = CacheEntry(data: data)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                switch policy {
                case .none:
                    break
                case .memoryOnly:
                    self.storeInMemory(entry, key: key)
                case .diskOnly:
                    self.storeToDisk(entry, key: key)
                case .memoryAndDisk, .automatic:
                    self.storeInMemory(entry, key: key)
                    self.storeToDisk(entry, key: key)
                }
                continuation.resume()
            }
        }
    }
    
    public func retrieve(for request: URLRequest) async -> CacheEntry? {
        let key = generateCacheKey(for: request)
        
        return await withCheckedContinuation { continuation in
            queue.async {
                // Try memory cache first
                if let entry = self.memoryCache.object(forKey: key as NSString) {
                    if !entry.isExpired {
                        continuation.resume(returning: entry)
                        return
                    } else {
                        self.memoryCache.removeObject(forKey: key as NSString)
                    }
                }
                
                // Try disk cache
                if let entry = self.retrieveFromDisk(key: key) {
                    if !entry.isExpired {
                        // Store back in memory for faster access
                        self.storeInMemory(entry, key: key)
                        continuation.resume(returning: entry)
                        return
                    } else {
                        self.removeFromDisk(key: key)
                    }
                }
                
                continuation.resume(returning: nil)
            }
        }
    }
    
    public func remove(for request: URLRequest) async {
        let key = generateCacheKey(for: request)
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                self.memoryCache.removeObject(forKey: key as NSString)
                self.removeFromDisk(key: key)
                continuation.resume()
            }
        }
    }
    
    public func clearAll() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                self.memoryCache.removeAllObjects()
                try? self.fileManager.removeItem(at: self.cacheDirectory)
                self.setupCache()
                self.currentDiskSize = 0
                continuation.resume()
            }
        }
    }
    
    public func clearExpired() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                // Clear expired memory entries (NSCache handles this automatically)
                
                // Clear expired disk entries
                guard let files = try? self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil) else {
                    continuation.resume()
                    return
                }
                
                for file in files {
                    if let entry = self.loadEntryFromDisk(url: file), entry.isExpired {
                        try? self.fileManager.removeItem(at: file)
                        self.currentDiskSize -= entry.size
                    }
                }
                
                continuation.resume()
            }
        }
    }
    
    public func getCacheSize() async -> Int {
        await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
            queue.async {
                continuation.resume(returning: self.currentDiskSize)
            }
        }
    }
    
    public func getCacheInfo() async -> CacheInfo {
        await withCheckedContinuation { (continuation: CheckedContinuation<CacheInfo, Never>) in
            queue.async {
                guard let files = try? self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
                    continuation.resume(returning: CacheInfo(totalSize: 0, entryCount: 0, oldestEntry: nil, newestEntry: nil, expiredCount: 0))
                    return
                }
                
                var totalSize = 0
                var oldestDate: Date?
                var newestDate: Date?
                var expiredCount = 0
                
                for file in files {
                    if let entry = self.loadEntryFromDisk(url: file) {
                        totalSize += entry.size
                        
                        if entry.isExpired {
                            expiredCount += 1
                        }
                        
                        if oldestDate == nil || entry.timestamp < oldestDate! {
                            oldestDate = entry.timestamp
                        }
                        
                        if newestDate == nil || entry.timestamp > newestDate! {
                            newestDate = entry.timestamp
                        }
                    }
                }
                
                let info = CacheInfo(
                    totalSize: totalSize,
                    entryCount: files.count,
                    oldestEntry: oldestDate,
                    newestEntry: newestDate,
                    expiredCount: expiredCount
                )
                
                continuation.resume(returning: info)
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupCache() {
        memoryCache.totalCostLimit = maxMemorySize
        
        // Create cache directory if needed
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Calculate current disk size
        calculateDiskSize()
    }
    
    private func generateCacheKey(for request: URLRequest) -> String {
        let url = request.url?.absoluteString ?? ""
        let method = request.httpMethod ?? "GET"
        let headers = request.allHTTPHeaderFields?.description ?? ""
        let body = request.httpBody?.base64EncodedString() ?? ""
        
        let combined = "\(method)|\(url)|\(headers)|\(body)"
        return combined.data(using: .utf8)?.base64EncodedString() ?? combined
    }
    
    private func storeInMemory(_ entry: CacheEntry, key: String) {
        memoryCache.setObject(entry, forKey: key as NSString, cost: entry.size)
    }
    
    private func storeToDisk(_ entry: CacheEntry, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        do {
            let cacheData: [String: Any] = [
                "data": entry.data.base64EncodedString(),
                "timestamp": entry.timestamp.timeIntervalSince1970,
                "expirationDate": entry.expirationDate.timeIntervalSince1970,
                "etag": entry.etag ?? "",
                "size": entry.size
            ]
            let encodedEntry = try JSONSerialization.data(withJSONObject: cacheData)
            
            try encodedEntry.write(to: fileURL)
            currentDiskSize += entry.size
            
            // Cleanup if needed
            if currentDiskSize > maxDiskSize {
                cleanupDiskCache()
            }
        } catch {
            // Handle error silently for cache operations
        }
    }
    
    private func retrieveFromDisk(key: String) -> CacheEntry? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        return loadEntryFromDisk(url: fileURL)
    }
    
    private func loadEntryFromDisk(url: URL) -> CacheEntry? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataString = json["data"] as? String,
              let entryData = Data(base64Encoded: dataString),
              let timestampInterval = json["timestamp"] as? TimeInterval,
              let expirationInterval = json["expirationDate"] as? TimeInterval,
              let _ = json["size"] as? Int else {
            return nil
        }
        
        let etag = json["etag"] as? String
        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        let expirationDate = Date(timeIntervalSince1970: expirationInterval)
        
        return CacheEntry.create(data: entryData, timestamp: timestamp, expirationDate: expirationDate, etag: etag)
    }
    
    private func removeFromDisk(key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if let entry = loadEntryFromDisk(url: fileURL) {
            currentDiskSize -= entry.size
        }
        try? fileManager.removeItem(at: fileURL)
    }
    
    private func calculateDiskSize() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            currentDiskSize = 0
            return
        }
        
        currentDiskSize = files.compactMap { url in
            loadEntryFromDisk(url: url)?.size
        }.reduce(0, +)
    }
    
    private func cleanupDiskCache() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        // Sort by creation date (oldest first)
        let sortedFiles = files.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 < date2
        }
        
        // Remove oldest files until we're under the limit
        for file in sortedFiles {
            if currentDiskSize <= maxDiskSize * 3 / 4 { break } // Leave some headroom
            
            if let entry = loadEntryFromDisk(url: file) {
                currentDiskSize -= entry.size
                try? fileManager.removeItem(at: file)
            }
        }
    }
}