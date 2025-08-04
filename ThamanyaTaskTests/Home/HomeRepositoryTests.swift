//
//  HomeRepositoryTests.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import XCTest
@testable import ThamanyaTask

final class HomeRepositoryTests: XCTestCase {
    
    var sut: HomeRepository!
    var mockNetworkService: MockNetworkService!
    
    override func setUpWithError() throws {
        mockNetworkService = MockNetworkService()
        sut = HomeRepository(networkService: mockNetworkService)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockNetworkService = nil
    }
    
    // MARK: - Fetch Home Sections Tests
    
    func testFetchHomeSections_Success() async throws {
        // Given
        let expectedResponse = HomeSectionsResponse(
            sections: [
                HomeSection(name: "Test Section", type: "square", contentType: "podcast", order: 1, content: [])
            ],
            pagination: Pagination(nextPage: nil, totalPages: 1)
        )
        mockNetworkService.homeSectionsResult = .success(expectedResponse)
        
        // When
        let result = try await sut.fetchHomeSections(page: 1)
        
        // Then
        XCTAssertEqual(result.sections.count, 1)
        XCTAssertEqual(result.sections.first?.name, "Test Section")
        XCTAssertEqual(result.pagination.totalPages, 1)
        XCTAssertEqual(mockNetworkService.executeCallCount, 1)
        XCTAssertNotNil(mockNetworkService.lastExecuteRequest)
        
        if let request = mockNetworkService.lastExecuteRequest {
            XCTAssertEqual(request.endpoint, "/home_sections")
            XCTAssertEqual(request.method, .GET)
            XCTAssertEqual(request.parameters?["page"] as? Int, 1)
        }
    }
    
    func testFetchHomeSections_DefaultPage() async throws {
        // Given
        let expectedResponse = HomeSectionsResponse(
            sections: [],
            pagination: Pagination(nextPage: nil, totalPages: 1)
        )
        mockNetworkService.homeSectionsResult = .success(expectedResponse)
        
        // When
        let result = try await sut.fetchHomeSections()
        
        // Then
        XCTAssertEqual(result.sections.count, 0)
        XCTAssertEqual(mockNetworkService.executeCallCount, 1)
        
        if let request = mockNetworkService.lastExecuteRequest {
            XCTAssertEqual(request.parameters?["page"] as? Int, 1)
        }
    }
    
    func testFetchHomeSections_NetworkError() async {
        // Given
        let networkError = NetworkError.networkError(URLError(.notConnectedToInternet).localizedDescription)
        mockNetworkService.homeSectionsResult = .failure(networkError)
        
        // When/Then
        do {
            _ = try await sut.fetchHomeSections(page: 1)
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
    
    func testFetchHomeSections_ServerError() async {
        // Given
        let serverError = NetworkError.serverError(500, "Internal Server Error")
        mockNetworkService.homeSectionsResult = .failure(serverError)
        
        // When/Then
        do {
            _ = try await sut.fetchHomeSections(page: 1)
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
    
    func testFetchHomeSections_NoDataError() async {
        // Given
        mockNetworkService.homeSectionsResult = .failure(NetworkError.noData)
        
        // When/Then
        do {
            _ = try await sut.fetchHomeSections(page: 1)
            XCTFail("Expected no data error")
        } catch let error as NetworkError {
            if case .noData = error {
                // Success - expected error type
            } else {
                XCTFail("Expected no data error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testFetchHomeSections_WithPagination() async throws {
        // Given
        let expectedResponse = HomeSectionsResponse(
            sections: [
                HomeSection(name: "Section 1", type: "square", contentType: "podcast", order: 1, content: []),
                HomeSection(name: "Section 2", type: "grid", contentType: "episode", order: 2, content: [])
            ],
            pagination: Pagination(nextPage: "/page3", totalPages: 5)
        )
        mockNetworkService.homeSectionsResult = .success(expectedResponse)
        
        // When
        let result = try await sut.fetchHomeSections(page: 2)
        
        // Then
        XCTAssertEqual(result.sections.count, 2)
        XCTAssertEqual(result.pagination.nextPage, "/page3")
        XCTAssertEqual(result.pagination.totalPages, 5)
        
        if let request = mockNetworkService.lastExecuteRequest {
            XCTAssertEqual(request.parameters?["page"] as? Int, 2)
        }
    }
    
    // MARK: - Factory Tests
    
    func testHomeRepositoryFactory() {
        // Given/When
        let repository = HomeRepositoryFactory.create()
        
        // Then
        XCTAssertNotNil(repository)
        XCTAssertTrue(repository is HomeRepository)
    }
} 