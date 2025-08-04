//
//  ThamanyaTaskApp.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import SwiftUI

@main
struct ThamanyaTaskApp: App {
    
    init() {
        // Configure dependencies synchronously
        AppConfiguration.configure(for: .development)
        
        // Debug: Print registered dependencies
        #if DEBUG
        DIContainer.shared.debugRegisteredDependencies()
        #endif
        
        // Setup logging level based on build configuration
        #if DEBUG
        if let logger: NetworkLogger = DIContainer.shared.resolveOptional(NetworkLogger.self) {
            logger.setLogLevel(.verbose)
        } else {
            print("⚠️ Warning: NetworkLogger not found in DI container")
        }
        #else
        if let logger: NetworkLogger = DIContainer.shared.resolveOptional(NetworkLogger.self) {
            logger.setLogLevel(.error)
        }
        #endif
        
        // Start network monitoring
        if let monitor: NetworkMonitoring = DIContainer.shared.resolveOptional(NetworkMonitoring.self) {
            monitor.startMonitoring()
        } else {
            print("⚠️ Warning: NetworkMonitoring not found in DI container")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupAppearance()
                }
        }
    }
    
    private func setupAppearance() {
        // Configure navigation bar appearance for dark theme
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.black
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Configure tab bar appearance for dark theme
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.black
        
        // Configure tab bar item appearance (images only, no text)
        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        tabBarItemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.clear]
        tabBarItemAppearance.normal.iconColor = UIColor(Color(hex: "A1A1A6"))
        tabBarItemAppearance.selected.iconColor = UIColor(Color(hex: "FFD60A"))
        
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Configure tint colors
        UITabBar.appearance().tintColor = UIColor(Color(hex: "FFD60A"))
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color(hex: "A1A1A6"))
        UINavigationBar.appearance().tintColor = UIColor(Color(hex: "FFD60A"))
        
        // Configure status bar style
       // UIApplication.shared.statusBarStyle = .lightContent
        
        // Configure scroll view appearance
        UIScrollView.appearance().backgroundColor = UIColor.black
        
        // Configure table view appearance
        UITableView.appearance().backgroundColor = UIColor.black
        UITableView.appearance().separatorColor = UIColor(Color(hex: "3A3A3C"))
        
//        // Configure text field appearance
//        UITextField.appearance().backgroundColor = UIColor(Color(hex: "1C1C1E"))
//        UITextField.appearance().textColor = UIColor.white
    }
}
