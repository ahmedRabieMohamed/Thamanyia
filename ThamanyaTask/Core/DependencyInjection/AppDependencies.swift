//
//  AppDependencies.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - App Dependencies Configurator
public final class AppDependencies {
    
    public static func configure() {
        configureNetworking()
        configureRepositories()
        configureViewModels()
    }
    
    // MARK: - Private Configuration Methods
    private static func configureNetworking() {
        let container = DIContainer.shared
        
        // Network Configuration
        let config = NetworkConfiguration(
            baseURL: "https://api-v2-b2sit6oh3a-uc.a.run.app",
            timeout: 30.0,
            retryCount: 3,
            retryDelay: 1.0,
            enableLogging: true,
            enableCaching: true
        )
        container.register(NetworkConfiguration.self, instance: config)
        
        // Create instances immediately to avoid circular dependencies
        let networkMonitor = NetworkMonitor()
        let networkLogger = NetworkLogger()
        let networkCache = NetworkCache()
        let interceptors: [NetworkInterceptor] = [
            LoggingInterceptor(logger: networkLogger),
            RateLimitingInterceptor(maxRequestsPerSecond: 10),
            ResponseValidationInterceptor()
        ]
        
        // Register instances
        container.register(NetworkMonitoring.self, instance: networkMonitor)
        container.register(NetworkLogger.self, instance: networkLogger)
        container.register(NetworkCache.self, instance: networkCache)
        container.register([NetworkInterceptor].self, instance: interceptors)
        
        // Network Service
        let networkService = NetworkServiceImplementation(
            configuration: config,
            interceptors: interceptors,
            monitor: networkMonitor,
            logger: networkLogger,
            cache: networkCache
        )
        container.register(NetworkServiceProtocol.self, instance: networkService)
    }
    
    private static func configureRepositories() {
        let container = DIContainer.shared
        
        // Get network service
        guard let networkService: NetworkServiceProtocol = container.resolveOptional(NetworkServiceProtocol.self) else {
            fatalError("NetworkServiceProtocol must be registered before repositories")
        }
        
        // Create repository instances
        let homeRepository = HomeRepository(networkService: networkService)
        let searchRepository = SearchRepository(networkService: networkService)
        
        // Register instances
        container.register(HomeRepositoryProtocol.self, instance: homeRepository)
        container.register(SearchRepositoryProtocol.self, instance: searchRepository)
    }
    
    private static func configureViewModels() {
        let container = DIContainer.shared
        
        // ViewModels are created on demand, so we keep them as factory registrations
        // But we ensure repositories are available
        guard let homeRepository: HomeRepositoryProtocol = container.resolveOptional(HomeRepositoryProtocol.self) else {
            fatalError("HomeRepositoryProtocol must be registered before view models")
        }
        
        guard let searchRepository: SearchRepositoryProtocol = container.resolveOptional(SearchRepositoryProtocol.self) else {
            fatalError("SearchRepositoryProtocol must be registered before view models")
        }
        
        // Home ViewModel
        container.register(HomeViewModel.self, scope: .transient) {
            return HomeViewModel(repository: homeRepository)
        }
        
        // Search ViewModel
        container.register(SearchViewModel.self, scope: .transient) {
            return SearchViewModel(repository: searchRepository)
        }
    }
}

// MARK: - Environment Configuration
public enum AppEnvironment {
    case development
    case staging
    case production
    
    public var baseURL: String {
        switch self {
        case .development:
            return "https://api-v2-b2sit6oh3a-uc.a.run.app"
        case .staging:
            return "https://staging-api-v2-b2sit6oh3a-uc.a.run.app" 
        case .production:
            return "https://api-v2-b2sit6oh3a-uc.a.run.app"
        }
    }
    
    public var enableLogging: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
}

// MARK: - App Configuration
public struct AppConfiguration {
    public static var currentEnvironment: AppEnvironment = .development
    
    public static func configure(for environment: AppEnvironment) {
        currentEnvironment = environment
        AppDependencies.configure()
    }
}
