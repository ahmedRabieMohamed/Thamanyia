//
//  SearchRepositoryTests.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import XCTest
@testable import ThamanyaTask

final class SearchRepositoryTests: XCTestCase {
    
    var sut: SearchRepository!
    var mockNetworkService: MockNetworkService!
    
    override func setUpWithError() throws {
        mockNetworkService = MockNetworkService()
        sut = SearchRepository(networkService: mockNetworkService)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockNetworkService = nil
    }
    
    // MARK: - Search Content Tests
    
    func testSearchContent_Success() async throws {
        // Given
        let expectedResponse = SearchResponse(
            sections: [
                SearchSection(name: "Search Results", type: "list", contentType: "podcast", order: "1", content: [])
            ]
        )
        mockNetworkService.searchResult = .success(expectedResponse)
        
        // When
        let result = try await sut.searchContent(query: "test query")
        
        // Then
        XCTAssertEqual(result.sections.count, 1)
        XCTAssertEqual(result.sections.first?.name, "Search Results")
        XCTAssertEqual(mockNetworkService.executeCallCount, 1)
        XCTAssertNotNil(mockNetworkService.lastExecuteRequest)
        
        if let request = mockNetworkService.lastExecuteRequest {
            XCTAssertTrue(request.endpoint.contains("search"))
            XCTAssertEqual(request.method, .GET)
            XCTAssertEqual(request.parameters?["q"] as? String, "test query")
        }
    }
    
    func testSearchContent_EmptyQuery() async throws {
        // When
        let result = try await sut.searchContent(query: "")
        
        // Then
        XCTAssertTrue(result.sections.isEmpty)
        XCTAssertEqual(mockNetworkService.executeCallCount, 0)
    }
    
    func testSearchContent_WhitespaceQuery() async throws {
        // When
        let result = try await sut.searchContent(query: "   ")
        
        // Then
        XCTAssertTrue(result.sections.isEmpty)
        XCTAssertEqual(mockNetworkService.executeCallCount, 0)
    }
    
    func testSearchContent_NetworkError() async {
        // Given
        let networkError = NetworkError.networkError(URLError(.notConnectedToInternet).localizedDescription)
        mockNetworkService.searchResult = .failure(networkError)
        
        // When/Then
        do {
            _ = try await sut.searchContent(query: "test")
            XCTFail("Expected network error")
        } catch let error as NetworkError {
            if case .networkError = error {
                // Success - expected error type
            } else {
                XCTFail("Expected network error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testSearchContent_ServerError() async {
        // Given
        let serverError = NetworkError.serverError(500, "Internal Server Error")
        mockNetworkService.searchResult = .failure(serverError)
        
        // When/Then
        do {
            _ = try await sut.searchContent(query: "test")
            XCTFail("Expected server error")
        } catch let error as NetworkError {
            if case .serverError = error {
                // Success - expected error type
            } else {
                XCTFail("Expected server error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testSearchContent_WithSpecialCharacters() async throws {
        // Given
        let expectedResponse = SearchResponse(sections: [])
        mockNetworkService.searchResult = .success(expectedResponse)
        
        // When
        let result = try await sut.searchContent(query: "test & query with special chars!")
        
        // Then
        XCTAssertEqual(mockNetworkService.executeCallCount, 1)
        
        if let request = mockNetworkService.lastExecuteRequest {
            XCTAssertEqual(request.parameters?["q"] as? String, "test & query with special chars!")
        }
    }
    
    // MARK: - Repository Factory Tests
    
    func testSearchRepositoryFactory() {
        // Given/When
        let repository = SearchRepositoryFactory.create()
        
        // Then
        XCTAssertNotNil(repository)
        XCTAssertTrue(repository is SearchRepository)
    }
}