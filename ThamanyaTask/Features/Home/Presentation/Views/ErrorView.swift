//
//  ErrorView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 02/08/2025.
//

import SwiftUI

// MARK: - Error View Component
struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "FFD60A"))
            
            Text("خطأ")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.white)
            
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(hex: "A1A1A6"))
                .multilineTextAlignment(.center)
            
            Button("إعادة المحاولة", action: retry)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(hex: "FF453A"))
                .cornerRadius(12)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
