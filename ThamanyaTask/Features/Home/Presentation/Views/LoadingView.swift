//
//  LoadingView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import SwiftUI

// MARK: - Loading View Component
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FFD60A")))
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "A1A1A6"))
        }
        .padding(24)
        .background(Color.black)
    }
} 