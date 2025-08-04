//
//  MockNetworkMonitor.swift
//  ThamanyaTaskTests
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
import Combine
@testable import ThamanyaTask

class MockNetworkMonitor: NetworkMonitoring {
    var isConnectedResult: Bool = true
    var networkStatusResult: NetworkStatus = .connected(.wifi)
    
    var isConnected: Bool {
        get async {
            return isConnectedResult
        }
    }
    
    var networkStatus: AnyPublisher<NetworkStatus, Never> {
        Just(networkStatusResult).eraseToAnyPublisher()
    }
    
    func startMonitoring() {
        // No-op for tests
    }
    
    func stopMonitoring() {
        // No-op for tests
    }
} 