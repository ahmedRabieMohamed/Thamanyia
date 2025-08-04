//
//  SearchBar.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 03/08/2025.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "A1A1A6"))
                .font(.system(size: 18, weight: .medium))
                .padding(.leading, 2)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .regular))
                        .padding(.horizontal, 6)
                }

                TextField("", text: $text)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .accentColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .background(Color.clear)
            }

            if !text.isEmpty {
                Button(action: { withAnimation { text = "" } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: "A1A1A6"))
                        .font(.system(size: 15, weight: .regular))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "3A3A3C"), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SearchBar(text: .constant(""), placeholder: "البحث عن البودكاست والحلقات...")
            .padding()
    }
}
