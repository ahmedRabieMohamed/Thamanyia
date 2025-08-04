//
//  NetworkServiceTests.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import XCTest
@testable import ThamanyaTask

final class NetworkServiceTests: XCTestCase {
    
    var sut: NetworkServiceImplementation!
    var mockSession: MockURLSession!
    var mockMonitor: MockNetworkMonitor!
    
    override func setUpWithError() throws {
        mockSession = MockURLSession()
        mockMonitor = MockNetworkMonitor()
        let config = NetworkConfiguration(
            baseURL: "https://test.com",
            timeout: 30.0,
            retryCount: 3,
            retryDelay: 1.0,
            enableLogging: false,
            enableCaching: false
        )
        sut = NetworkServiceImplementation(session: mockSession, configuration: config, monitor: mockMonitor)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockSession = nil
        mockMonitor = nil
    }
    
    // MARK: - Fetch Home Sections Tests
    
    func testExecuteHomeSections_Success() async throws {
        // Given
        let expectedResponse = HomeSectionsResponse(
            sections: [
                HomeSection(name: "Test Section", type: "square", contentType: "podcast", order: 1, content: [])
            ],
            pagination: Pagination(nextPage: nil, totalPages: 1)
        )
        
        let jsonData = try JSONEncoder().encode(expectedResponse)
        mockSession.data = jsonData
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": 1],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When
        let result: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
        
        // Then
        XCTAssertEqual(result.sections.count, 1)
        XCTAssertEqual(result.sections.first?.name, "Test Section")
        XCTAssertEqual(result.pagination.totalPages, 1)
        XCTAssertEqual(mockSession.dataCallCount, 1)
    }
    
    func testExecuteHomeSections_NetworkError() async {
        // Given
        mockSession.error = URLError(.notConnectedToInternet)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": 1],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
            XCTFail("Expected network error")
        } catch let error as NetworkError {
            if case .noInternetConnection = error {
                // Success - expected error type
            } else {
                XCTFail("Expected noInternetConnection error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testExecuteHomeSections_ServerError() async {
        // Given
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": 1],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
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
    
    func testExecuteHomeSections_InvalidStatusCode() async {
        // Given
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": 1],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
            XCTFail("Expected not found error")
        } catch let error as NetworkError {
            if case .notFound = error {
                // Success - expected error type
            } else {
                XCTFail("Expected notFound error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testExecuteHomeSections_NoData() async {
        // Given
        mockSession.data = nil
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": 1],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
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
    
    func testExecuteHomeSections_InvalidJSON() async {
        // Given
        let invalidJSON = "invalid json".data(using: .utf8)!
        mockSession.data = invalidJSON
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": 1],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
            XCTFail("Expected decoding error")
        } catch {
            // Success - expected decoding error
        }
    }
    
    // MARK: - Search Content Tests
    
    func testExecuteSearchContent_Success() async throws {
        // Given
        let expectedResponse = SearchResponse(
            sections: [
                SearchSection(name: "Search Results", type: "list", contentType: "podcast", order: "1", content: [])
            ]
        )
        
        let jsonData = try JSONEncoder().encode(expectedResponse)
        mockSession.data = jsonData
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/search",
            method: .GET,
            parameters: ["q": "test"],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When
        let result: SearchResponse = try await sut.execute(request, responseType: SearchResponse.self)
        
        // Then
        XCTAssertEqual(result.sections.count, 1)
        XCTAssertEqual(result.sections.first?.name, "Search Results")
        XCTAssertEqual(mockSession.dataCallCount, 1)
    }
    
    func testExecuteSearchContent_NetworkError() async {
        // Given
        mockSession.error = URLError(.notConnectedToInternet)
        
        let request = APIRequest(
            endpoint: "/search",
            method: .GET,
            parameters: ["q": "test"],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: SearchResponse = try await sut.execute(request, responseType: SearchResponse.self)
            XCTFail("Expected network error")
        } catch let error as NetworkError {
            if case .noInternetConnection = error {
                // Success - expected error type
            } else {
                XCTFail("Expected noInternetConnection error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testExecuteSearchContent_ServerError() async {
        // Given
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/search",
            method: .GET,
            parameters: ["q": "test"],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: SearchResponse = try await sut.execute(request, responseType: SearchResponse.self)
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
    
    func testExecuteSearchContent_InvalidJSON() async {
        // Given
        let invalidJSON = "invalid json".data(using: .utf8)!
        mockSession.data = invalidJSON
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/search",
            method: .GET,
            parameters: ["q": "test"],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: SearchResponse = try await sut.execute(request, responseType: SearchResponse.self)
            XCTFail("Expected decoding error")
        } catch {
            // Success - expected decoding error
        }
    }
    
    // MARK: - Execute Method Tests
    
    func testExecute_Success() async throws {
        // Given
        let expectedResponse = HomeSectionsResponse(
            sections: [
                HomeSection(name: "Test Section", type: "square", contentType: "podcast", order: 1, content: [])
            ],
            pagination: Pagination(nextPage: nil, totalPages: 1)
        )
        
        let jsonData = try JSONEncoder().encode(expectedResponse)
        mockSession.data = jsonData
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": 1],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When
        let result: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
        
        // Then
        XCTAssertEqual(result.sections.count, 1)
        XCTAssertEqual(result.sections.first?.name, "Test Section")
    }
    
    func testExecute_NetworkError() async {
        // Given
        mockSession.error = URLError(.notConnectedToInternet)
        
        let request = APIRequest(
            endpoint: "/test",
            method: .GET,
            parameters: [:],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
            XCTFail("Expected network error")
        } catch let error as NetworkError {
            if case .noInternetConnection = error {
                // Success - expected error type
            } else {
                XCTFail("Expected noInternetConnection error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testExecute_ServerError() async {
        // Given
        mockSession.data = Data()
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/test",
            method: .GET,
            parameters: [:],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
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
    
    func testExecute_NoData() async {
        // Given
        mockSession.data = nil
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/test",
            method: .GET,
            parameters: [:],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When/Then
        do {
            let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
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
    
    // MARK: - URL Construction Tests
    
    func testURLConstruction_WithParameters() async throws {
        // Given
        let expectedResponse = HomeSectionsResponse(sections: [], pagination: Pagination(nextPage: nil, totalPages: 1))
        let jsonData = try JSONEncoder().encode(expectedResponse)
        mockSession.data = jsonData
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: ["page": 1, "limit": 10],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When
        let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
        
        // Then
        XCTAssertEqual(mockSession.dataCallCount, 1)
        XCTAssertNotNil(mockSession.lastDataRequest)
        if let urlRequest = mockSession.lastDataRequest {
            XCTAssertTrue(urlRequest.url?.absoluteString.contains("page=1") ?? false)
            XCTAssertTrue(urlRequest.url?.absoluteString.contains("limit=10") ?? false)
        }
    }
    
    func testURLConstruction_WithoutParameters() async throws {
        // Given
        let expectedResponse = HomeSectionsResponse(sections: [], pagination: Pagination(nextPage: nil, totalPages: 1))
        let jsonData = try JSONEncoder().encode(expectedResponse)
        mockSession.data = jsonData
        mockSession.response = HTTPURLResponse(url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        let request = APIRequest(
            endpoint: "/home_sections",
            method: .GET,
            parameters: [:],
            cachePolicy: .returnCacheDataElseLoad
        )
        
        // When
        let _: HomeSectionsResponse = try await sut.execute(request, responseType: HomeSectionsResponse.self)
        
        // Then
        XCTAssertEqual(mockSession.dataCallCount, 1)
        XCTAssertNotNil(mockSession.lastDataRequest)
        if let urlRequest = mockSession.lastDataRequest {
            XCTAssertFalse(urlRequest.url?.absoluteString.contains("?") ?? true)
        }
    }
} 