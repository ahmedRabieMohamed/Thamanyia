//
//  MockHomeRepository.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
@testable import ThamanyaTask

class MockHomeRepository: HomeRepositoryProtocol {
    var fetchHomeSectionsResult: Result<HomeSectionsResponse, Error> = .success(
        HomeSectionsResponse(sections: [], pagination: Pagination(nextPage: nil, totalPages: 1))
    )
    
    var fetchHomeSectionsCallCount = 0
    var lastFetchHomeSectionsPage: Int?
    
    func fetchHomeSections(page: Int) async throws -> HomeSectionsResponse {
        fetchHomeSectionsCallCount += 1
        lastFetchHomeSectionsPage = page
        
        switch fetchHomeSectionsResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
} 