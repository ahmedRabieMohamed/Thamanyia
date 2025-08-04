//
//  HomeRepository.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - Home Repository Protocol
public protocol HomeRepositoryProtocol {
    func fetchHomeSections(page: Int) async throws -> HomeSectionsResponse
}

// MARK: - Home Repository Implementation
public final class HomeRepository: HomeRepositoryProtocol {
    
    // MARK: - Properties
    private let networkService: NetworkServiceProtocol
    
    // MARK: - Initialization
    public init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - Public Methods
    public func fetchHomeSections(page: Int = 1) async throws -> HomeSectionsResponse {
        print("🏠 HomeRepository: fetchHomeSections called for page \(page)")
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": page],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        print("🏠 HomeRepository: About to call networkService.execute")
        let result = try await networkService.execute(request, responseType: HomeSectionsResponse.self)
        print("🏠 HomeRepository: networkService.execute completed")
        return result
    }

}

// MARK: - Home Repository Factory
public final class HomeRepositoryFactory {
    public static func create() -> HomeRepositoryProtocol {
        let networkService: NetworkServiceProtocol = DIContainer.shared.resolve(NetworkServiceProtocol.self)
        return HomeRepository(networkService: networkService)
    }
}
