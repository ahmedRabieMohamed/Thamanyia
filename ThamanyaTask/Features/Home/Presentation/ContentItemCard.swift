//
//  ContentItemCard.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import SwiftUI

// MARK: - Content Item Style
enum ContentItemStyle {
    case square
    case twoLines
    case bigSquare
    case list
}

// MARK: - Content Item Card
struct ContentItemCard: View {
    let item: SectionContent
    let style: ContentItemStyle
    
    var body: some View {
        switch style {
        case .square:
            SquareCardView(item: item)
        case .twoLines:
            TwoLinesCardView(item: item)
        case .bigSquare:
            BigSquareCardView(item: item)
        case .list:
            ListCardView(item: item)
        }
    }
}

// MARK: - Square Card View
struct SquareCardView: View {
    let item: SectionContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image only
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
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Title - single line with ellipsis
            Text(item.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.white)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // Relative time
            if let releaseDate = item.releaseDate {
                Text(formatRelativeTime(from: releaseDate))
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(Color(hex: "A1A1A6"))
            }
            
            // Duration/play button and time section
            HStack(spacing: 8) {
                // Duration and play button with rounded background
                HStack(spacing: 6) {
                    Text(item.duration.formatDuration())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white)
                    
                    Button(action: {
                        // Play action
                    }) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.white)
                            .frame(width: 16, height: 16)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(8)
                
            }
        }
        .frame(width: 120)
    }
}

// MARK: - Two Lines Card View
struct TwoLinesCardView: View {
    let item: SectionContent
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 15) {
            // Image
            AsyncImage(url: URL(string: item.avatarURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color(hex: "2C2C2E"))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(Color(hex: "A1A1A6"))
                    }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 8) {
                
                Text(item.name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Text("5 hours ago")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let authorName = item.authorName {
                    Text(authorName)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "A1A1A6"))
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(8)
        .background(Color(hex: "272937"))
        .cornerRadius(15)
    }
}

// MARK: - Big Square Card View
struct BigSquareCardView: View {
    let item: SectionContent
    
    var body: some View {
        HStack(spacing: 15) {
            // Image
            AsyncImage(url: URL(string: item.avatarURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color(hex: "2C2C2E"))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(Color(hex: "A1A1A6"))
                    }
            }
            .frame(width: 150, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Text Content
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.white)
                
                if let authorName = item.authorName {
                    Text(authorName)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "A1A1A6"))
                        .lineLimit(1)
                }
                
                Text(item.description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "A1A1A6"))
                    .lineLimit(3)
                
                HStack {
                    Text(item.duration.formatDuration())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "FFD60A"))
                    
                    Spacer()
                    
                    if let episodeCount = item.episodeCount {
                        Text("\(episodeCount) حلقة")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "A1A1A6"))
                    }
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(hex: "272937"))
        .cornerRadius(15)
        .frame(width: UIScreen.main.bounds.width - 55)
    }
}

// MARK: - List Card View
struct ListCardView: View {
    let item: SectionContent
    
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
                
                if let authorName = item.authorName {
                    Text(authorName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "A1A1A6"))
                        .lineLimit(1)
                }
                
                HStack {
                    Text(item.duration.formatDuration())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "FFD60A"))
                    
                    Text("•")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "A1A1A6"))
                    
                    if let episodeCount = item.episodeCount {
                        Text("\(episodeCount) حلقة")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "A1A1A6"))
                    }
                    
                    Spacer()
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

// MARK: - Helper Functions

private func formatRelativeTime(from dateString: String) -> String {
    let formatter = DateFormatter()
    
    // Try different date formats that might be used
    let formats = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd"
    ]
    
    var date: Date?
    for format in formats {
        formatter.dateFormat = format
        if let parsedDate = formatter.date(from: dateString) {
            date = parsedDate
            break
        }
    }
    
    guard let date = date else {
        return dateString // Return original string if parsing fails
    }
    
    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: date, to: now)
    
    if let years = components.year, years > 0 {
        return years == 1 ? "قبل سنة" : "قبل \(years) سنوات"
    } else if let months = components.month, months > 0 {
        return months == 1 ? "قبل شهر" : "قبل \(months) أشهر"
    } else if let weeks = components.weekOfYear, weeks > 0 {
        return weeks == 1 ? "قبل أسبوع" : "قبل \(weeks) أسابيع"
    } else if let days = components.day, days > 0 {
        if days == 1 {
            return "أمس"
        } else if days < 7 {
            return "قبل \(days) أيام"
        } else {
            return "قبل أسبوع"
        }
    } else if let hours = components.hour, hours > 0 {
        return hours == 1 ? "قبل ساعة" : "قبل \(hours) ساعات"
    } else if let minutes = components.minute, minutes > 0 {
        return minutes == 1 ? "قبل دقيقة" : "قبل \(minutes) دقائق"
    } else {
        return "الآن"
    }
}

#Preview {
    VStack(spacing: 24) {
        ContentItemCard(
            item: SectionContent(
                name: "Sample Podcast",
                description: "This is a sample podcast description",
                avatarURL: "https://via.placeholder.com/200",
                duration: 3600,
                score: 4.5,
                podcastID: "123",
                episodeCount: 100,
                language: "en",
                priority: 1,
                popularityScore: 90,
                authorName: "Sample Author"
            ),
            style: .square
        )
        
        ContentItemCard(
            item: SectionContent(
                name: "Sample Episode",
                description: "This is a sample episode description that can be longer",
                avatarURL: "https://via.placeholder.com/200",
                duration: 1800,
                score: 4.8,
                episodeID: "456",
                language: "en",
                priority: 1,
                popularityScore: 95,
                podcastName: "Sample Podcast",
                authorName: "Sample Host",
                seasonNumber: 1,
                episodeType: "full",
                number: 10,
                audioURL: "https://example.com/audio.mp3",
                releaseDate: "2024-01-01",
                chapters: []
            ),
            style: .list
        )
    }
    .padding(24)
    .background(Color.black)
}
