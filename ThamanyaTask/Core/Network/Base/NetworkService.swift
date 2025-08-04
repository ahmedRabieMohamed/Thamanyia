//
//  NetworkService.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
import Network
import Combine

// MARK: - Network Configuration
public struct NetworkConfiguration {
    let baseURL: String
    let timeout: TimeInterval
    let retryCount: Int
    let retryDelay: TimeInterval
    let enableLogging: Bool
    let enableCaching: Bool
    
    public init(
        baseURL: String,
        timeout: TimeInterval = 30.0,
        retryCount: Int = 3,
        retryDelay: TimeInterval = 1.0,
        enableLogging: Bool = true,
        enableCaching: Bool = true
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.retryCount = retryCount
        self.retryDelay = retryDelay
        self.enableLogging = enableLogging
        self.enableCaching = enableCaching
    }
}

// MARK: - HTTP Method
public enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Network Request Protocol
public protocol NetworkRequest {
    var endpoint: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
    var body: Data? { get }
    var cachePolicy: URLRequest.CachePolicy { get }
}

// MARK: - Network Request Implementation
public struct APIRequest: NetworkRequest {
    public let endpoint: String
    public let method: HTTPMethod
    public let headers: [String: String]?
    public let parameters: [String: Any]?
    public let body: Data?
    public let cachePolicy: URLRequest.CachePolicy
    
    public init(
        endpoint: String,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        parameters: [String: Any]? = nil,
        body: Data? = nil,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) {
        self.endpoint = endpoint
        self.method = method
        self.headers = headers
        self.parameters = parameters
        self.body = body
        self.cachePolicy = cachePolicy
    }
}

// MARK: - Advanced Network Error
public enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case noData
    case decodingError(String)
    case encodingError(String)
    case serverError(Int, String)
    case networkError(String)
    case timeout
    case cancelled
    case noInternetConnection
    case unauthorised
    case forbidden
    case notFound
    case rateLimited
    case serverMaintenance
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .noData:
            return "No data received from server"
        case .decodingError(let details):
            return "Failed to decode response: \(details)"
        case .encodingError(let details):
            return "Failed to encode request: \(details)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .networkError(let details):
            return "Network error: \(details)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .noInternetConnection:
            return "No internet connection available"
        case .unauthorised:
            return "Unauthorized access - please login"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests - please try again later"
        case .serverMaintenance:
            return "Server is under maintenance"
        case .unknown(let details):
            return "Unknown error: \(details)"
        }
    }
    
    public var errorCode: Int {
        switch self {
        case .invalidURL: return -1000
        case .noData: return -1001
        case .decodingError: return -1002
        case .encodingError: return -1003
        case .serverError(let code, _): return code
        case .networkError: return -1004
        case .timeout: return -1005
        case .cancelled: return -1006
        case .noInternetConnection: return -1007
        case .unauthorised: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .rateLimited: return 429
        case .serverMaintenance: return 503
        case .unknown: return -9999
        }
    }
}

// MARK: - URLSession Protocol
public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: nil)
    }
}

// MARK: - Network Service Protocol
public protocol NetworkServiceProtocol {
    func execute<T: Codable>(_ request: NetworkRequest, responseType: T.Type) async throws -> T
    func executeWithRaw(_ request: NetworkRequest) async throws -> Data
    func cancel(_ request: NetworkRequest)
    func cancelAllRequests()
}