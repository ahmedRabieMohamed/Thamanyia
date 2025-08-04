//
//  ContentView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("")
                }
                .id("home")
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass") 
                    Text("")
                }
                .id("search")

        }
        .background(Color.black)
        .onAppear {
            // Additional setup to ensure text is hidden
            UITabBar.appearance().itemPositioning = .centered
        }
    }
}

#Preview {
    ContentView()
}
