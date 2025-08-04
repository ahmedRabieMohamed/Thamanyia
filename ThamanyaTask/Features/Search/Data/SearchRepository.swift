//
//  SearchRepository.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - Search Repository Protocol
public protocol SearchRepositoryProtocol {
    func searchContent(query: String) async throws -> SearchResponse
}

// MARK: - Search Repository Implementation
public final class SearchRepository: SearchRepositoryProtocol {
    
    // MARK: - Properties
    private let networkService: NetworkServiceProtocol
    private let baseURL = "https://mock.apidog.com/m1/735111-711675-default"
    
    // MARK: - Initialization
    public init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - Public Methods
    public func searchContent(query: String) async throws -> SearchResponse {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return SearchResponse(sections: [])
        }
        
        let request = APIRequest(
            endpoint: "\(baseURL)/search",
            method: .GET,
            parameters: ["q": query],
            cachePolicy: .useProtocolCachePolicy
        )
        
        let result = try await networkService.execute(request, responseType: SearchResponse.self)
        
        return result
    }
    

}



// MARK: - Search Repository Factory
public final class SearchRepositoryFactory {
    public static func create() -> SearchRepositoryProtocol {
        let networkService: NetworkServiceProtocol = DIContainer.shared.resolve(NetworkServiceProtocol.self)
        return SearchRepository(networkService: networkService)
    }
}

