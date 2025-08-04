//
//  SearchResultCard.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 04/08/2025.
//

import SwiftUI

struct SearchResultCard: View {
    let item: SearchContent
    
    var body: some View {
        HStack(spacing: 16) {
            // Image with overlay play button
            ZStack(alignment: .center) {
                AsyncImage(url: URL(string: item.avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(hex: "2C2C2E"))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(Color(hex: "A1A1A6"))
                        }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Play button overlay on image
                Button(action: {
                    // Play action
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white)
                        .frame(width: 28, height: 28)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(item.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "A1A1A6"))
                    .lineLimit(2)
                
                HStack {
                    if let duration = Int(item.duration), duration > 0 {
                        Text(duration.formatDuration())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "FFD60A"))
                        
                        Text("•")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "A1A1A6"))
                    }
                    
                    if let episodeCount = Int(item.episodeCount), episodeCount > 0 {
                        Text("\(episodeCount) حلقة")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "A1A1A6"))
                    }
                    
                    Spacer()
                    
                    if let score = Double(item.score), score > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(hex: "FFD60A"))
                                .font(.caption2)
                            Text(String(format: "%.1f", score))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color(hex: "A1A1A6"))
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}
