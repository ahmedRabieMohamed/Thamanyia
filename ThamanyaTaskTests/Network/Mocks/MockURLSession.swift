//
//  MockURLSession.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
@testable import ThamanyaTask

class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    var dataCallCount = 0
    var lastDataRequest: URLRequest?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        dataCallCount += 1
        lastDataRequest = request
        
        if let error = error {
            throw error
        }
        
        guard let data = data, let response = response else {
            throw NetworkError.noData
        }
        
        return (data, response)
    }
} 