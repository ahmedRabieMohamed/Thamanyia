//
//  SearchViewModel.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
import Combine

// MARK: - Search View Model
public final class SearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var searchText = ""
    @Published public var searchResults: [SearchSection] = []
    @Published public var loadingState: LoadingState = .idle
    @Published public var errorAlert: Error?
    
    // MARK: - Private Properties
    private let repository: SearchRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private var lastSearchQuery: String = ""
    
    // MARK: - Initialization
    public init(repository: SearchRepositoryProtocol) {
        self.repository = repository
        setupSearchDebouncing()
    }
    
    // Convenience initializer for legacy support
    public convenience init() {
        let repository: SearchRepositoryProtocol = DIContainer.shared.resolve(SearchRepositoryProtocol.self)
        self.init(repository: repository)
    }
    
    // MARK: - Public Methods
    public func performSearch() async {
        await search(query: searchText)
    }
    
    public func clearSearch() {
        searchText = ""
        searchResults = []
        loadingState = .idle
        lastSearchQuery = ""
        cancelCurrentSearch()
    }
    

    
    public func retrySearch() async {
        // For retry, we want to bypass the duplicate query check
        await performSearch(query: searchText, forceRetry: true)
    }
    
    // MARK: - Private Methods
    private func setupSearchDebouncing() {
        // Debounce search text changes with 200ms delay as per task requirements
        $searchText
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task { @MainActor in
                    await self?.handleSearchTextChange(searchText)
                }
            }
            .store(in: &cancellables)
        

    }
    
    private func handleSearchTextChange(_ text: String) async {
        let trimmedText = text.trimmed
        
        if trimmedText.isEmpty {
            await MainActor.run {
                searchResults = []
                loadingState = .idle
            }
            cancelCurrentSearch()
        } else {
            // Perform search
            await performSearch(query: trimmedText, forceRetry: false)
        }
    }
    
    private func search(query: String) async {
        await performSearch(query: query, forceRetry: false)
    }
    
    private func performSearch(query: String, forceRetry: Bool = false) async {
        let trimmedQuery = query.trimmed
        
        guard !trimmedQuery.isEmpty else {
            await MainActor.run {
                searchResults = []
                loadingState = .idle
            }
            return
        }
        
        // Prevent duplicate searches for the same query, unless it's a retry
        if !forceRetry {
            guard trimmedQuery != lastSearchQuery else {
                return
            }
        }
        
        // Cancel previous search
        cancelCurrentSearch()
        
        // Update last search query
        lastSearchQuery = trimmedQuery
        
        await MainActor.run {
            loadingState = .loading
        }
        
        searchTask = Task {
            do {
                let response = try await repository.searchContent(query: trimmedQuery)
                
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    self.searchResults = response.sections
                    self.loadingState = .loaded
                }
                
            } catch {
                // Check if task was cancelled
                guard !Task.isCancelled else { return }
                
                await self.handleError(error)
            }
        }
    }
    

    
    private func cancelCurrentSearch() {
        searchTask?.cancel()
        searchTask = nil
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

// MARK: - SearchViewModel + Analytics
extension SearchViewModel {
    public func trackSearchPerformed(_ query: String, resultCount: Int) {
        // Analytics tracking would go here
        print("📊 Search performed: '\(query)' with \(resultCount) results")
    }
    
    public func trackSearchResultTapped(_ content: SearchContent, position: Int) {
        // Analytics tracking would go here
        print("📊 Search result tapped: \(content.name) at position \(position)")
    }
    

}

// MARK: - SearchViewModel + Testing
#if DEBUG
extension SearchViewModel {
    public static func mock() -> SearchViewModel {
        let mockRepository = MockSearchRepository()
        return SearchViewModel(repository: mockRepository)
    }
}

// MARK: - Mock Repository for Testing
private class MockSearchRepository: SearchRepositoryProtocol {
    func searchContent(query: String) async throws -> SearchResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let mockContent = SearchContent(
            podcastID: "mock-id",
            name: "Mock Result for '\(query)'",
            description: "This is a mock search result for testing purposes",
            avatarURL: "https://via.placeholder.com/200",
            episodeCount: "10",
            duration: "3600",
            language: "en",
            priority: "1",
            popularityScore: "90",
            score: "95"
        )
        
        let mockSection = SearchSection(
            name: "Search Results",
            type: "list",
            contentType: "podcast",
            order: "1",
            content: [mockContent]
        )
        
        return SearchResponse(sections: [mockSection])
    }
    

}
#endif
