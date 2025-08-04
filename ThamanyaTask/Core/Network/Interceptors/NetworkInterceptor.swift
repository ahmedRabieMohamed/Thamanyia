//
//  NetworkInterceptor.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - Network Interceptor Protocol
public protocol NetworkInterceptor {
    func intercept(request: NetworkRequest) async throws -> NetworkRequest
    func intercept(response: Data, urlResponse: URLResponse) async throws -> Data
}

// MARK: - Authentication Interceptor
public final class AuthenticationInterceptor: NetworkInterceptor {
    private let tokenProvider: () async -> String?
    
    public init(tokenProvider: @escaping () async -> String?) {
        self.tokenProvider = tokenProvider
    }
    
    public func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        let modifiedRequest = request
        
        if let token = await tokenProvider() {
            var headers = modifiedRequest.headers ?? [:]
            headers["Authorization"] = "Bearer \(token)"
            
            return APIRequest(
                endpoint: modifiedRequest.endpoint,
                method: modifiedRequest.method,
                headers: headers,
                parameters: modifiedRequest.parameters,
                body: modifiedRequest.body,
                cachePolicy: modifiedRequest.cachePolicy
            )
        }
        
        return modifiedRequest
    }
    
    public func intercept(response: Data, urlResponse: URLResponse) async throws -> Data {
        return response
    }
}

// MARK: - Logging Interceptor
public final class LoggingInterceptor: NetworkInterceptor {
    private let logger: NetworkLogger
    
    public init(logger: NetworkLogger = NetworkLogger()) {
        self.logger = logger
    }
    
    public func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        await logger.log(.info("🚀 Outgoing Request: \(request.method.rawValue) \(request.endpoint)"))
        
        if let headers = request.headers, !headers.isEmpty {
            await logger.log(.info("📋 Headers: \(headers)"))
        }
        
        if let parameters = request.parameters, !parameters.isEmpty {
            await logger.log(.info("📝 Parameters: \(parameters)"))
        }
        
        return request
    }
    
    public func intercept(response: Data, urlResponse: URLResponse) async throws -> Data {
        if let httpResponse = urlResponse as? HTTPURLResponse {
            await logger.log(.info("📡 Response: \(httpResponse.statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"))
            await logger.log(.info("📦 Response Size: \(response.count) bytes"))
        }
        
        return response
    }
}

// MARK: - Rate Limiting Interceptor
public final class RateLimitingInterceptor: NetworkInterceptor {
    private let maxRequestsPerSecond: Int
    private var requestTimes: [Date] = []
    private let queue = DispatchQueue(label: "rate.limiting.queue", attributes: .concurrent)
    private let lock = NSLock()
    
    public init(maxRequestsPerSecond: Int = 10) {
        self.maxRequestsPerSecond = maxRequestsPerSecond
    }
    
    public func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        await enforceRateLimit()
        return request
    }
    
    public func intercept(response: Data, urlResponse: URLResponse) async throws -> Data {
        return response
    }
    
    private func enforceRateLimit() async {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                let now = Date()
                let oneSecondAgo = now.addingTimeInterval(-1.0)
                
                // Thread-safe access to requestTimes
                self.lock.lock()
                defer { self.lock.unlock() }
                
                // Remove old timestamps
                self.requestTimes.removeAll { timestamp in
                    timestamp < oneSecondAgo
                }
                
                // Check if we need to wait
                if self.requestTimes.count >= self.maxRequestsPerSecond {
                    let delay = 1.0 / Double(self.maxRequestsPerSecond)
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self else {
                            continuation.resume()
                            return
                        }
                        self.lock.lock()
                        self.requestTimes.append(Date())
                        self.lock.unlock()
                        continuation.resume()
                    }
                } else {
                    self.requestTimes.append(now)
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Response Validation Interceptor
public final class ResponseValidationInterceptor: NetworkInterceptor {
    public func intercept(request: NetworkRequest) async throws -> NetworkRequest {
        return request
    }
    
    public func intercept(response: Data, urlResponse: URLResponse) async throws -> Data {
        // Validate response structure
        guard !response.isEmpty else {
            throw NetworkError.noData
        }
        
        // Try to parse as JSON to validate structure
        do {
            _ = try JSONSerialization.jsonObject(with: response, options: [])
        } catch {
            throw NetworkError.decodingError("Invalid JSON response")
        }
        
        return response
    }
}
