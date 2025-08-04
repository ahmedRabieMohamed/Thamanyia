//
//  MockSearchRepository.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
@testable import ThamanyaTask

class MockSearchRepository: SearchRepositoryProtocol {
    var searchContentResult: Result<SearchResponse, Error> = .success(SearchResponse(sections: []))
    
    var searchContentCallCount = 0
    var lastSearchContentQuery: String?
    
    func searchContent(query: String) async throws -> SearchResponse {
        searchContentCallCount += 1
        lastSearchContentQuery = query
        
        switch searchContentResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
    

} 