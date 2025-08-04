//
//  HomeViewModel.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
import Combine

// MARK: - Loading State
public enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
    
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    public var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}

// MARK: - Home View Model
public final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var sections: [HomeSection] = []
    @Published public var loadingState: LoadingState = .idle
    @Published public var currentPage = 1
    @Published public var hasMorePages = true
    @Published public var errorAlert: Error?
    
    // MARK: - Private Properties
    private let repository: HomeRepositoryProtocol
    private var totalPages = 1
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(repository: HomeRepositoryProtocol) {
        self.repository = repository
        setupBindings()
    }
    
    // Convenience initializer for legacy support
    public convenience init() {
        let repository: HomeRepositoryProtocol = DIContainer.shared.resolve(HomeRepositoryProtocol.self)
        self.init(repository: repository)
    }
    
    // MARK: - Public Methods
    public func loadHomeSections() async {
        print("🏠 HomeViewModel: loadHomeSections() called")
        
        await MainActor.run {
            loadingState = .loading
            currentPage = 1
        }
        
        do {
            let response = try await repository.fetchHomeSections(page: currentPage)
            
            await MainActor.run {
                sections = response.sections
                totalPages = response.pagination.totalPages
                hasMorePages = response.pagination.nextPage != nil
                loadingState = .loaded
            }
            
        } catch {
            await handleError(error)
        }
    }
    
    public func loadMoreSections() async {
        // Check conditions first
        let shouldLoad = await MainActor.run {
            guard hasMorePages && loadingState != .loading else { return false }
            return true
        }
        
        guard shouldLoad else { return }
        
        let nextPage = currentPage + 1
        
        do {
            let response = try await repository.fetchHomeSections(page: nextPage)
            
            await MainActor.run {
                sections.append(contentsOf: response.sections)
                currentPage = nextPage
                hasMorePages = response.pagination.nextPage != nil
            }
            
        } catch {
            await handleError(error)
        }
    }
    

    
    public func retryLoading() async {
        await loadHomeSections()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        print("🏠 HomeViewModel: setupBindings() called")
        // No automatic loading - let the view handle initial load
    }
    
    private func handleError(_ error: Error) async {
        await MainActor.run {
            if let networkError = error as? NetworkError {
                loadingState = .error(networkError.localizedDescription)
            } else {
                loadingState = .error(error.localizedDescription)
            }
            errorAlert = error
        }
    }
}

// MARK: - HomeViewModel + Analytics
extension HomeViewModel {
    public func trackSectionView(_ section: HomeSection) {
        // Analytics tracking would go here
        print("📊 Section viewed: \(section.name)")
    }
    
    public func trackContentInteraction(_ content: SectionContent, in section: HomeSection) {
        // Analytics tracking would go here
        print("📊 Content interaction: \(content.name) in \(section.name)")
    }
}

// MARK: - HomeViewModel + Testing
#if DEBUG
extension HomeViewModel {
    public static func mock() -> HomeViewModel {
        let mockRepository = MockHomeRepository()
        return HomeViewModel(repository: mockRepository)
    }
}

// MARK: - Mock Repository for Testing
private class MockHomeRepository: HomeRepositoryProtocol {
    func fetchHomeSections(page: Int) async throws -> HomeSectionsResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let mockSections = [
            HomeSection(
                name: "Mock Section \(page)",
                type: "square",
                contentType: "podcast",
                order: page,
                content: []
            )
        ]
        
        return HomeSectionsResponse(
            sections: mockSections,
            pagination: Pagination(nextPage: page < 3 ? "/page\(page + 1)" : nil, totalPages: 3)
        )
    }
    
    func refreshHomeSections() async throws -> HomeSectionsResponse {
        return try await fetchHomeSections(page: 1)
    }
}
#endif
