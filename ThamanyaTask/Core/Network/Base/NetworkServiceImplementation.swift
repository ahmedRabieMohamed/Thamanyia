//
//  NetworkServiceImplementation.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
import Combine

// MARK: - Advanced Network Service Implementation
public final class NetworkServiceImplementation: NetworkServiceProtocol {
    
    // MARK: - Properties
    private let session: URLSessionProtocol
    private let configuration: NetworkConfiguration
    private let interceptors: [NetworkInterceptor]
    private let monitor: NetworkMonitoring
    private let logger: NetworkLogger
    private let cache: NetworkCache
    private var activeTasks: [String: Task<Data, Error>] = [:]
    private let queue = DispatchQueue(label: "network.service.queue", qos: .utility)
    
    // MARK: - Initialization
    public init(
        session: URLSessionProtocol = URLSession.shared,
        configuration: NetworkConfiguration,
        interceptors: [NetworkInterceptor] = [],
        monitor: NetworkMonitoring = NetworkMonitor(),
        logger: NetworkLogger = NetworkLogger(),
        cache: NetworkCache = NetworkCache()
    ) {
        self.session = session
        self.configuration = configuration
        self.interceptors = interceptors
        self.monitor = monitor
        self.logger = logger
        self.cache = cache
    }
    
    // MARK: - Public Methods
    public func execute<T: Codable>(_ request: NetworkRequest, responseType: T.Type) async throws -> T {
        let data = try await executeWithRaw(request)
        
        do {
            let response = try JSONDecoder().decode(T.self, from: data)
            await logger.log(.response(data: data, model: String(describing: T.self)))
            return response
        } catch {
            await logger.log(.error(.decodingError(error.localizedDescription)))
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
    
    public func executeWithRaw(_ request: NetworkRequest) async throws -> Data {
        // Check network connectivity
        guard await monitor.isConnected else {
            throw NetworkError.noInternetConnection
        }
        
        // Build URL request
        let urlRequest = try await buildURLRequest(from: request)
        let requestID = UUID().uuidString
        
        return try await withTaskCancellationHandler {
            try await executeRequestWithRetry(urlRequest, requestID: requestID, retryCount: configuration.retryCount)
        } onCancel: {
            self.cancel(request)
        }
    }
    
    public func cancel(_ request: NetworkRequest) {
        queue.async {
            let requestKey = self.generateRequestKey(for: request)
            self.activeTasks[requestKey]?.cancel()
            self.activeTasks.removeValue(forKey: requestKey)
        }
    }
    
    public func cancelAllRequests() {
        queue.async {
            for task in self.activeTasks.values {
                task.cancel()
            }
            self.activeTasks.removeAll()
        }
    }
    
    // MARK: - Private Methods
    private func buildURLRequest(from request: NetworkRequest) async throws -> URLRequest {
        // Apply request interceptors
        var modifiedRequest = request
        for interceptor in interceptors {
            modifiedRequest = try await interceptor.intercept(request: modifiedRequest)
        }
        
        // Build URL - handle both relative endpoints and full URLs
        let urlString: String
        if modifiedRequest.endpoint.hasPrefix("http://") || modifiedRequest.endpoint.hasPrefix("https://") {
            // Endpoint is already a full URL
            urlString = modifiedRequest.endpoint
        } else {
            // Endpoint is relative, prepend base URL
            urlString = configuration.baseURL + modifiedRequest.endpoint
        }
        var urlComponents = URLComponents(string: urlString)
        
        // Add query parameters for GET requests
        if modifiedRequest.method == .GET, let parameters = modifiedRequest.parameters, !parameters.isEmpty {
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
        
        guard let url = urlComponents?.url else {
            await logger.log(.error(.invalidURL))
            throw NetworkError.invalidURL
        }
        
        // Create URL request
        var urlRequest = URLRequest(url: url, cachePolicy: modifiedRequest.cachePolicy, timeoutInterval: configuration.timeout)
        urlRequest.httpMethod = modifiedRequest.method.rawValue
        
        // Add headers
        var headers = modifiedRequest.headers ?? [:]
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body for non-GET requests
        if modifiedRequest.method != .GET {
            if let body = modifiedRequest.body {
                urlRequest.httpBody = body
            } else if let parameters = modifiedRequest.parameters {
                do {
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                } catch {
                    await logger.log(.error(.encodingError(error.localizedDescription)))
                    throw NetworkError.encodingError(error.localizedDescription)
                }
            }
        }
        
        // Request logging is handled by LoggingInterceptor
        return urlRequest
    }
    
    private func executeRequestWithRetry(_ request: URLRequest, requestID: String, retryCount: Int) async throws -> Data {
        let requestKey = generateRequestKey(for: request)
        
        let task = Task<Data, Error> {
            do {
                let (data, response) = try await session.data(for: request)
                
                // Apply response interceptors
                var finalData = data
                for interceptor in interceptors {
                    finalData = try await interceptor.intercept(response: finalData, urlResponse: response)
                }
                
                try validateResponse(response)
                
                // Cache successful responses
                if configuration.enableCaching {
                    await cache.store(data: finalData, for: request)
                }
                
                return finalData
                
            } catch {
                await logger.log(.error(mapError(error)))
                
                // Retry logic
                if retryCount > 0 && shouldRetry(error: error) {
                    await logger.log(.info("Retrying request. Attempts remaining: \(retryCount)"))
                    try await Task.sleep(nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000))
                    return try await executeRequestWithRetry(request, requestID: requestID, retryCount: retryCount - 1)
                }
                
                throw mapError(error)
            }
        }
        
        // Store active task
        queue.sync {
            activeTasks[requestKey] = task
        }
        
        defer {
            queue.async {
                self.activeTasks.removeValue(forKey: requestKey)
            }
        }
        
        return try await task.value
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Invalid response type")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break // Success
        case 401:
            throw NetworkError.unauthorised
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            if httpResponse.statusCode == 503 {
                throw NetworkError.serverMaintenance
            } else {
                throw NetworkError.serverError(httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
            }
        default:
            throw NetworkError.serverError(httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }
    }
    
    private func shouldRetry(error: Error) -> Bool {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .timeout, .networkError:
                return true
            case .serverError(let code, _):
                return code >= 500 // Retry server errors
            default:
                return false
            }
        }
        return false
    }
    
    private func mapError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternetConnection
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            default:
                return .networkError(urlError.localizedDescription)
            }
        }
        
        return .unknown(error.localizedDescription)
    }
    
    private func generateRequestKey(for request: NetworkRequest) -> String {
        return "\(request.method.rawValue)_\(request.endpoint)"
    }
    
    private func generateRequestKey(for request: URLRequest) -> String {
        return "\(request.httpMethod ?? "GET")_\(request.url?.absoluteString ?? "")"
    }
}
