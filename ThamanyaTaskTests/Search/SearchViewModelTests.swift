//
//  SearchViewModelTests.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import XCTest
import Combine
@testable import ThamanyaTask

@MainActor
final class SearchViewModelTests: XCTestCase {
    
    var sut: SearchViewModel!
    var mockRepository: MockSearchRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        mockRepository = MockSearchRepository()
        sut = SearchViewModel(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockRepository = nil
        cancellables = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_DefaultValues() {
        XCTAssertEqual(sut.searchText, "")
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertEqual(sut.loadingState, .idle)
        XCTAssertNil(sut.errorAlert)
    }
    
    func testInitialization_WithRepository() {
        let repository = MockSearchRepository()
        let viewModel = SearchViewModel(repository: repository)
        
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }
    
    // MARK: - Search Content Tests
    
    func testSearchContent_Success() async {
        // Given
        let expectedSections = [
            SearchSection(name: "Search Results", type: "list", contentType: "podcast", order: "1", content: [])
        ]
        mockRepository.searchContentResult = .success(SearchResponse(sections: expectedSections))
        
        // When - Set search text to trigger debounced search
        sut.searchText = "test"
        
        // Then - Wait for debounce and search to complete
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(sut.searchResults.first?.name, "Search Results")
        XCTAssertEqual(mockRepository.searchContentCallCount, 1)
        XCTAssertEqual(mockRepository.lastSearchContentQuery, "test")
    }
    
    func testSearchContent_WithQuery() async {
        // Given
        let expectedSections = [
            SearchSection(name: "Search Results", type: "list", contentType: "podcast", order: "1", content: [])
        ]
        mockRepository.searchContentResult = .success(SearchResponse(sections: expectedSections))
        
        // When - Set search text to trigger debounced search
        sut.searchText = "test query"
        
        // Then - Wait for debounce and search to complete
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(mockRepository.lastSearchContentQuery, "test query")
    }
    
    func testSearchContent_EmptyQuery() async {
        // When - Set empty search text
        sut.searchText = ""
        
        // Then - Wait for debounce
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        XCTAssertEqual(sut.loadingState, .idle)
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertEqual(mockRepository.searchContentCallCount, 0)
    }
    
    func testSearchContent_WhitespaceQuery() async {
        // Given
        sut.searchText = "   "
        
        // When - Wait for debounce
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        // Then
        XCTAssertEqual(sut.loadingState, .idle)
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertEqual(mockRepository.searchContentCallCount, 0)
    }
    
    func testSearchContent_NetworkError() async {
        // Given
        let networkError = NetworkError.networkError(URLError(.notConnectedToInternet).localizedDescription)
        mockRepository.searchContentResult = .failure(networkError)
        
        // When - Set search text to trigger debounced search
        sut.searchText = "test"
        
        // Then - Wait for debounce and search to complete
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        if case .error(let message) = sut.loadingState {
            XCTAssertTrue(message.contains("Network error"))
        } else {
            XCTFail("Expected error state")
        }
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertNotNil(sut.errorAlert)
    }
    
    func testSearchContent_ServerError() async {
        // Given
        let serverError = NetworkError.serverError(500, "Internal Server Error")
        mockRepository.searchContentResult = .failure(serverError)
        
        // When - Set search text to trigger debounced search
        sut.searchText = "test"
        
        // Then - Wait for debounce and search to complete
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        if case .error(let message) = sut.loadingState {
            XCTAssertTrue(message.contains("Internal Server Error"))
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testSearchContent_DuplicateQuery() async {
        // Given
        let expectedSections = [
            SearchSection(name: "Search Results", type: "list", contentType: "podcast", order: "1", content: [])
        ]
        mockRepository.searchContentResult = .success(SearchResponse(sections: expectedSections))
        
        // When - First search
        sut.searchText = "test"
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        let firstCallCount = mockRepository.searchContentCallCount
        
        // When - Second search with same query
        sut.searchText = "test"
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        // Then - Should not make additional call due to duplicate prevention
        XCTAssertEqual(mockRepository.searchContentCallCount, firstCallCount)
    }
    
    // MARK: - Clear Search Tests
    
    func testClearSearch() {
        // Given
        sut.searchText = "test query"
        sut.searchResults = [
            SearchSection(name: "Test", type: "list", contentType: "podcast", order: "1", content: [])
        ]
        sut.loadingState = .loaded
        
        // When
        sut.clearSearch()
        
        // Then
        XCTAssertEqual(sut.searchText, "")
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertEqual(sut.loadingState, .idle)
    }
    

    
    // MARK: - Retry Search Tests
    
    func testRetrySearch() async {
        // Given - First set up a successful search
        let expectedSections = [
            SearchSection(name: "Search Results", type: "list", contentType: "podcast", order: "1", content: [])
        ]
        mockRepository.searchContentResult = .success(SearchResponse(sections: expectedSections))
        
        // Set initial search text and wait for it to complete
        sut.searchText = "test"
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        // Reset call count to measure only the retry call
        mockRepository.searchContentCallCount = 0
        
        // Now set up an error scenario for retry
        let networkError = NetworkError.networkError(URLError(.notConnectedToInternet).localizedDescription)
        mockRepository.searchContentResult = .failure(networkError)
        
        // Change search text to trigger a new search that will fail
        sut.searchText = "retry test"
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms to account for 200ms debounce
        
        // Verify we're in error state
        if case .error = sut.loadingState {
            // Good, we're in error state
        } else {
            XCTFail("Expected error state before retry")
            return
        }
        
        // Reset call count and set up success for retry
        mockRepository.searchContentCallCount = 0
        mockRepository.searchContentResult = .success(SearchResponse(sections: expectedSections))
        
        // When - Call retry search
        await sut.retrySearch()
        
        // Then - Wait for the retry operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms for the retry operation
        
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(mockRepository.searchContentCallCount, 1)
        XCTAssertEqual(mockRepository.lastSearchContentQuery, "retry test")
    }
    
    // MARK: - Search Text Debounce Tests
    
    func testSearchTextDebounce() async {
        // Given
        let expectation = XCTestExpectation(description: "Search should be triggered after debounce")
        expectation.expectedFulfillmentCount = 1
        
        mockRepository.searchContentResult = .success(SearchResponse(sections: []))
        
        // Observe loading state changes
        sut.$loadingState
            .sink { state in
                if state == .loading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Set search text
        sut.searchText = "test"
        
        // Then - Wait for debounce
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testSearchTextDebounce_MultipleChanges() async {
        // Given
        let expectation = XCTestExpectation(description: "Search should be triggered only once after multiple changes")
        expectation.expectedFulfillmentCount = 1
        
        mockRepository.searchContentResult = .success(SearchResponse(sections: []))
        
        var loadingCount = 0
        sut.$loadingState
            .sink { state in
                if state == .loading {
                    loadingCount += 1
                    if loadingCount == 1 {
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)
        
        // When - Set search text multiple times quickly
        sut.searchText = "t"
        sut.searchText = "te"
        sut.searchText = "tes"
        sut.searchText = "test"
        
        // Then - Wait for debounce
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Give a bit more time to ensure no additional searches are triggered
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        XCTAssertEqual(loadingCount, 1, "Search should be triggered only once")
    }
    
    func testSearchTextDebounce_EmptyText() async {
        // Given
        let expectation = XCTestExpectation(description: "State should reset when text is empty")
        expectation.expectedFulfillmentCount = 1
        
        sut.$loadingState
            .sink { state in
                if state == .idle {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Set search text then clear it
        sut.searchText = "test"
        sut.searchText = ""
        
        // Then - Wait for debounce
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(sut.loadingState, .idle)
        XCTAssertTrue(sut.searchResults.isEmpty)
    }
    
    // MARK: - Analytics Tests
    
    func testTrackSearchPerformed() {
        // Given
        let query = "test query"
        let resultCount = 5
        
        // When/Then - Should not crash
        sut.trackSearchPerformed(query, resultCount: resultCount)
    }
    
    func testTrackSearchResultTapped() {
        // Given
        let content = SearchContent(podcastID: "test-id", name: "Test Content", description: "Test", avatarURL: "https://test.com", episodeCount: "5", duration: "3600", language: "en", priority: "1", popularityScore: "90", score: "95")
        let position = 1
        
        // When/Then - Should not crash
        sut.trackSearchResultTapped(content, position: position)
    }
    

    
    // MARK: - Mock Tests
    
    func testMockSearchViewModel() {
        // Given/When
        let mockViewModel = SearchViewModel.mock()
        
        // Then
        XCTAssertNotNil(mockViewModel)
        XCTAssertEqual(mockViewModel.searchText, "")
        XCTAssertTrue(mockViewModel.searchResults.isEmpty)
    }
} 