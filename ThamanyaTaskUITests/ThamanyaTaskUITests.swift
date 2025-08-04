//
//  ThamanyaTaskUITests.swift
//  ThamanyaTaskUITests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import XCTest

final class ThamanyaTaskUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testMainScreenNavigation() throws {
        // Test tab navigation between Home and Search
        
        // Wait for the app to load
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist")
        
        // Get all tab bar buttons
        let tabBarButtons = tabBar.buttons.allElementsBoundByIndex
        
        // Verify we have at least 2 tabs (Home and Search)
        XCTAssertGreaterThanOrEqual(tabBarButtons.count, 2, "Should have at least 2 tab buttons")
        
        // First tab should be Home (index 0)
        let homeTabButton = tabBarButtons[0]
        XCTAssertTrue(homeTabButton.exists, "Home tab should exist")
        
        // Second tab should be Search (index 1)
        let searchTabButton = tabBarButtons[1]
        XCTAssertTrue(searchTabButton.exists, "Search tab should exist")
        
        // Verify Home tab is selected by default
        XCTAssertTrue(homeTabButton.isSelected, "Home tab should be selected by default")
        XCTAssertFalse(searchTabButton.isSelected, "Search tab should not be selected initially")
        
        // Navigate to Search tab
        searchTabButton.tap()
        
        // Verify Search tab is now selected
        XCTAssertTrue(searchTabButton.isSelected, "Search tab should be selected after tap")
        XCTAssertFalse(homeTabButton.isSelected, "Home tab should not be selected after switching")
        
        // Navigate back to Home tab
        homeTabButton.tap()
        XCTAssertTrue(homeTabButton.isSelected, "Home tab should be selected after switching back")
        XCTAssertFalse(searchTabButton.isSelected, "Search tab should not be selected after switching back")
    }
    
    func testHomeScreenElements() throws {
        // Verify Home screen elements are present
        
        // Check if content loads (wait for sections to appear)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: app.scrollViews.firstMatch
        )
        wait(for: [expectation], timeout: 10.0)
        
        // Verify scroll view exists
        XCTAssertTrue(app.scrollViews.firstMatch.exists)
    }
    
    func testAppLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
