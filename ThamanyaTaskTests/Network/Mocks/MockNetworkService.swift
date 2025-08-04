//
//  MockNetworkService.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
@testable import ThamanyaTask

class MockNetworkService: NetworkServiceProtocol {
    var homeSectionsResult: Result<HomeSectionsResponse, Error> = .success(
        HomeSectionsResponse(sections: [], pagination: Pagination(nextPage: nil, totalPages: 1))
    )
    var searchResult: Result<SearchResponse, Error> = .success(SearchResponse(sections: []))
    
    var executeCallCount = 0
    var lastExecuteRequest: NetworkRequest?
    var executeWithRawCallCount = 0
    var cancelCallCount = 0
    var cancelAllRequestsCallCount = 0
    
    func execute<T: Codable>(_ request: NetworkRequest, responseType: T.Type) async throws -> T {
        executeCallCount += 1
        lastExecuteRequest = request
        
        // Determine which result to return based on the request endpoint
        if request.endpoint.contains("home_sections") {
            switch homeSectionsResult {
            case .success(let response):
                return response as! T
            case .failure(let error):
                throw error
            }
        } else if request.endpoint.contains("search") {
            switch searchResult {
            case .success(let response):
                return response as! T
            case .failure(let error):
                throw error
            }
        } else {
            throw NetworkError.noData
        }
    }
    
    func executeWithRaw(_ request: NetworkRequest) async throws -> Data {
        executeWithRawCallCount += 1
        lastExecuteRequest = request
        
        // Return mock data based on endpoint
        if request.endpoint.contains("home_sections") {
            switch homeSectionsResult {
            case .success(let response):
                return try JSONEncoder().encode(response)
            case .failure(let error):
                throw error
            }
        } else if request.endpoint.contains("search") {
            switch searchResult {
            case .success(let response):
                return try JSONEncoder().encode(response)
            case .failure(let error):
                throw error
            }
        } else {
            throw NetworkError.noData
        }
    }
    
    func cancel(_ request: NetworkRequest) {
        cancelCallCount += 1
    }
    
    func cancelAllRequests() {
        cancelAllRequestsCallCount += 1
    }
} 