//
//  NetworkMonitor.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
import Network
import Combine

// MARK: - Network Status
public enum NetworkStatus: Equatable {
    case connected(ConnectionType)
    case disconnected
    case unknown
}

// MARK: - Connection Type
public enum ConnectionType: Equatable {
    case wifi
    case cellular
    case ethernet
    case other
}

// MARK: - Network Monitoring Protocol
public protocol NetworkMonitoring {
    var isConnected: Bool { get async }
    var networkStatus: AnyPublisher<NetworkStatus, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

// MARK: - Network Monitor Implementation
public final class NetworkMonitor: NetworkMonitoring {
    
    // MARK: - Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let statusSubject = CurrentValueSubject<NetworkStatus, Never>(.unknown)
    
    // MARK: - Public Properties
    public var isConnected: Bool {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    let isConnected = self.monitor.currentPath.status == .satisfied
                    continuation.resume(returning: isConnected)
                }
            }
        }
    }
    
    public var networkStatus: AnyPublisher<NetworkStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    public init() {
        setupMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    public func startMonitoring() {
        monitor.start(queue: queue)
    }
    
    public func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Private Methods
    private func setupMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        startMonitoring()
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        let status: NetworkStatus
        
        switch path.status {
        case .satisfied:
            let connectionType = determineConnectionType(path)
            status = .connected(connectionType)
        case .unsatisfied, .requiresConnection:
            status = .disconnected
        @unknown default:
            status = .unknown
        }
        
        statusSubject.send(status)
    }
    
    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .other
        }
    }
}