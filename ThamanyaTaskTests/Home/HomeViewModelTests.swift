//
//  HomeViewModelTests.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import XCTest
import Combine
@testable import ThamanyaTask

@MainActor
final class HomeViewModelTests: XCTestCase {
    
    var sut: HomeViewModel!
    var mockRepository: MockHomeRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        mockRepository = MockHomeRepository()
        sut = HomeViewModel(repository: mockRepository)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockRepository = nil
        cancellables = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_DefaultValues() {
        // Note: setupBindings() automatically calls loadHomeSections()
        // So we need to wait for the initial load to complete
        XCTAssertEqual(sut.currentPage, 1)
        XCTAssertTrue(sut.hasMorePages)
        XCTAssertNil(sut.errorAlert)
    }
    
    func testInitialization_WithRepository() {
        let repository = MockHomeRepository()
        let viewModel = HomeViewModel(repository: repository)
        
        // Note: setupBindings() automatically calls loadHomeSections()
        // So we can't test the initial idle state
        XCTAssertEqual(viewModel.currentPage, 1)
        XCTAssertTrue(viewModel.hasMorePages)
    }
    
    // MARK: - Load Home Sections Tests
    
    func testLoadHomeSections_Success() async {
        // Given
        let expectedSections = [
            HomeSection(name: "Test Section 1", type: "square", contentType: "podcast", order: 1, content: []),
            HomeSection(name: "Test Section 2", type: "grid", contentType: "episode", order: 2, content: [])
        ]
        
        mockRepository.fetchHomeSectionsResult = .success(
            HomeSectionsResponse(sections: expectedSections, pagination: Pagination(nextPage: "/page2", totalPages: 3))
        )
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        
        // When
        await sut.loadHomeSections()
        
        // Then
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertEqual(sut.sections.count, 2)
        XCTAssertEqual(sut.sections.first?.name, "Test Section 1")
        XCTAssertEqual(sut.currentPage, 1)
        XCTAssertTrue(sut.hasMorePages)
        XCTAssertEqual(mockRepository.fetchHomeSectionsCallCount, 1)
        XCTAssertEqual(mockRepository.lastFetchHomeSectionsPage, 1)
    }
    
    func testLoadHomeSections_NetworkError() async {
        // Given
        let networkError = NetworkError.networkError(URLError(.notConnectedToInternet).localizedDescription)
        mockRepository.fetchHomeSectionsResult = .failure(networkError)
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        
        // When
        await sut.loadHomeSections()
        
        // Then
        if case .error(let message) = sut.loadingState {
            XCTAssertTrue(message.contains("Network error"))
        } else {
            XCTFail("Expected error state")
        }
        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertEqual(sut.currentPage, 1)
        XCTAssertNotNil(sut.errorAlert)
    }
    
    func testLoadHomeSections_ServerError() async {
        // Given
        let serverError = NetworkError.serverError(500, "Internal Server Error")
        mockRepository.fetchHomeSectionsResult = .failure(serverError)
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        
        // When
        await sut.loadHomeSections()
        
        // Then
        if case .error(let message) = sut.loadingState {
            XCTAssertTrue(message.contains("Internal Server Error"))
        } else {
            XCTFail("Expected error state")
        }
        XCTAssertTrue(sut.sections.isEmpty)
    }
    
    func testLoadHomeSections_NoDataError() async {
        // Given
        mockRepository.fetchHomeSectionsResult = .failure(NetworkError.noData)
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        
        // When
        await sut.loadHomeSections()
        
        // Then
        if case .error(let message) = sut.loadingState {
            XCTAssertTrue(message.contains("No data"))
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testLoadHomeSections_EmptySections() async {
        // Given
        mockRepository.fetchHomeSectionsResult = .success(
            HomeSectionsResponse(sections: [], pagination: Pagination(nextPage: nil, totalPages: 1))
        )
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        
        // When
        await sut.loadHomeSections()
        
        // Then
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertTrue(sut.sections.isEmpty)
        XCTAssertFalse(sut.hasMorePages)
    }
    
    // MARK: - Load More Sections Tests
    
    func testLoadMoreSections_Success() async {
        // Given - Initial load
        let initialSections = [
            HomeSection(name: "Section 1", type: "square", contentType: "podcast", order: 1, content: [])
        ]
        mockRepository.fetchHomeSectionsResult = .success(
            HomeSectionsResponse(sections: initialSections, pagination: Pagination(nextPage: "/page2", totalPages: 2))
        )
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        await sut.loadHomeSections()
        
        // Given - Load more
        let moreSections = [
            HomeSection(name: "Section 2", type: "grid", contentType: "episode", order: 2, content: [])
        ]
        mockRepository.fetchHomeSectionsResult = .success(
            HomeSectionsResponse(sections: moreSections, pagination: Pagination(nextPage: nil, totalPages: 2))
        )
        
        // When
        await sut.loadMoreSections()
        
        // Then
        XCTAssertEqual(sut.sections.count, 2)
        XCTAssertEqual(sut.currentPage, 2)
        XCTAssertFalse(sut.hasMorePages)
        XCTAssertEqual(mockRepository.fetchHomeSectionsCallCount, 2)
        XCTAssertEqual(mockRepository.lastFetchHomeSectionsPage, 2)
    }
    
    func testLoadMoreSections_NoMorePages() async {
        // Given
        let sections = [
            HomeSection(name: "Section 1", type: "square", contentType: "podcast", order: 1, content: [])
        ]
        mockRepository.fetchHomeSectionsResult = .success(
            HomeSectionsResponse(sections: sections, pagination: Pagination(nextPage: nil, totalPages: 1))
        )
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        await sut.loadHomeSections()
        
        // Verify that hasMorePages is false
        XCTAssertFalse(sut.hasMorePages)
        
        let initialSectionCount = sut.sections.count
        let initialCallCount = mockRepository.fetchHomeSectionsCallCount
        
        // When - hasMorePages should be false, so loadMoreSections should not execute
        await sut.loadMoreSections()
        
        // Then
        XCTAssertEqual(sut.sections.count, initialSectionCount) // No new sections added
        XCTAssertEqual(sut.currentPage, 1) // Page didn't increment
        XCTAssertEqual(mockRepository.fetchHomeSectionsCallCount, initialCallCount) // No additional call
    }
    
    func testLoadMoreSections_WhileLoading() async {
        // Given
        let sections = [
            HomeSection(name: "Section 1", type: "square", contentType: "podcast", order: 1, content: [])
        ]
        mockRepository.fetchHomeSectionsResult = .success(
            HomeSectionsResponse(sections: sections, pagination: Pagination(nextPage: "/page2", totalPages: 2))
        )
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        await sut.loadHomeSections()
        
        // Verify that hasMorePages is true
        XCTAssertTrue(sut.hasMorePages)
        
        let initialSectionCount = sut.sections.count
        let initialCallCount = mockRepository.fetchHomeSectionsCallCount
        
        // Set loading state to prevent loadMoreSections from executing
        sut.loadingState = .loading
        
        // When
        await sut.loadMoreSections()
        
        // Then
        XCTAssertEqual(sut.sections.count, initialSectionCount) // No new sections added
        XCTAssertEqual(sut.currentPage, 1) // Page didn't increment
        XCTAssertEqual(mockRepository.fetchHomeSectionsCallCount, initialCallCount) // No additional call
    }
    
    func testLoadMoreSections_Error() async {
        // Given - Initial load
        let initialSections = [
            HomeSection(name: "Section 1", type: "square", contentType: "podcast", order: 1, content: [])
        ]
        mockRepository.fetchHomeSectionsResult = .success(
            HomeSectionsResponse(sections: initialSections, pagination: Pagination(nextPage: "/page2", totalPages: 2))
        )
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        await sut.loadHomeSections()
        
        let initialSectionCount = sut.sections.count
        
        // Given - Error on load more
        let networkError = NetworkError.networkError(URLError(.notConnectedToInternet).localizedDescription)
        mockRepository.fetchHomeSectionsResult = .failure(networkError)
        
        // When
        await sut.loadMoreSections()
        
        // Then
        XCTAssertEqual(sut.sections.count, initialSectionCount) // Original sections remain
        XCTAssertEqual(sut.currentPage, 1) // Page didn't increment
        if case .error(let message) = sut.loadingState {
            XCTAssertTrue(message.contains("Network error"))
        } else {
            XCTFail("Expected error state")
        }
    }
    
    // MARK: - Retry Loading Tests
    
    func testRetryLoading() async {
        // Given
        let sections = [
            HomeSection(name: "Section 1", type: "square", contentType: "podcast", order: 1, content: [])
        ]
        mockRepository.fetchHomeSectionsResult = .success(
            HomeSectionsResponse(sections: sections, pagination: Pagination(nextPage: nil, totalPages: 1))
        )
        
        // Reset call count after initial setup call
        mockRepository.fetchHomeSectionsCallCount = 0
        
        // When
        await sut.retryLoading()
        
        // Then
        XCTAssertEqual(sut.loadingState, .loaded)
        XCTAssertEqual(sut.sections.count, 1)
        XCTAssertEqual(sut.currentPage, 1)
        XCTAssertEqual(mockRepository.fetchHomeSectionsCallCount, 1) // Only the retry call
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingState_IsLoading() {
        // Given
        sut.loadingState = .loading
        
        // Then
        XCTAssertTrue(sut.loadingState.isLoading)
    }
    
    func testLoadingState_NotLoading() {
        // Given
        sut.loadingState = .loaded
        
        // Then
        XCTAssertFalse(sut.loadingState.isLoading)
    }
    
    func testLoadingState_ErrorMessage() {
        // Given
        let errorMessage = "Test error message"
        sut.loadingState = .error(errorMessage)
        
        // Then
        XCTAssertEqual(sut.loadingState.errorMessage, errorMessage)
    }
    
    func testLoadingState_NoErrorMessage() {
        // Given
        sut.loadingState = .loaded
        
        // Then
        XCTAssertNil(sut.loadingState.errorMessage)
    }
    
    // MARK: - Analytics Tests
    
    func testTrackSectionView() {
        // Given
        let section = HomeSection(name: "Test Section", type: "square", contentType: "podcast", order: 1, content: [])
        
        // When/Then - Should not crash
        sut.trackSectionView(section)
    }
    
    func testTrackContentInteraction() {
        // Given
        let section = HomeSection(name: "Test Section", type: "square", contentType: "podcast", order: 1, content: [])
        let content = SectionContent(name: "Test Content", description: "Test", avatarURL: "https://test.com", duration: 3600, score: 95.0, podcastID: "test-id", episodeCount: 5, language: "en", priority: 1, popularityScore: 90)
        
        // When/Then - Should not crash
        sut.trackContentInteraction(content, in: section)
    }
    
    // MARK: - Mock Tests
    
    func testMockHomeViewModel() {
        // Given/When
        let mockViewModel = HomeViewModel.mock()
        
        // Then
        XCTAssertNotNil(mockViewModel)
        // Note: Mock view model also has automatic loading, so we can't test initial state
        XCTAssertEqual(mockViewModel.currentPage, 1)
        XCTAssertTrue(mockViewModel.hasMorePages)
    }
} 