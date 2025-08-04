//
//  HomeSectionModels.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - Home Sections Response
public struct HomeSectionsResponse: Codable {
    public let sections: [HomeSection]
    public let pagination: Pagination
    
    public init(sections: [HomeSection], pagination: Pagination) {
        self.sections = sections
        self.pagination = pagination
    }
}

// MARK: - Home Section
public struct HomeSection: Codable, Identifiable {
    public let id = UUID()
    public let name: String
    public let type: String
    public let contentType: String
    public let order: Int
    public let content: [SectionContent]
    
    public init(name: String, type: String, contentType: String, order: Int, content: [SectionContent]) {
        self.name = name
        self.type = type
        self.contentType = contentType
        self.order = order
        self.content = content
    }
    
    enum CodingKeys: String, CodingKey {
        case name, type, order, content
        case contentType = "content_type"
    }
}

// MARK: - Section Content (Union Type)
public struct SectionContent: Codable, Identifiable {
    public let id = UUID()
    
    // Common fields
    public let name: String
    public let description: String
    public let avatarURL: String
    public let duration: Int
    public let score: Double
    
    // Podcast/Episode specific fields
    public let podcastID: String?
    public let episodeID: String?
    public let episodeCount: Int?
    public let language: String?
    public let priority: Int?
    public let popularityScore: Int?
    public let podcastName: String?
    public let authorName: String?
    public let seasonNumber: Int?
    public let episodeType: String?
    public let number: Int?
    public let audioURL: String?
    public let releaseDate: String?
    public let chapters: [String]?
    
    // Audiobook specific fields
    public let audiobookID: String?
    
    // Article specific fields
    public let articleID: String?
    
    enum CodingKeys: String, CodingKey {
        case name, description, duration, score, language, priority, number, chapters
        case avatarURL = "avatar_url"
        case podcastID = "podcast_id"
        case episodeID = "episode_id"
        case episodeCount = "episode_count"
        case popularityScore = "popularityScore"
        case podcastName = "podcast_name"
        case authorName = "author_name"
        case seasonNumber = "season_number"
        case episodeType = "episode_type"
        case audioURL = "audio_url"
        case releaseDate = "release_date"
        case audiobookID = "audiobook_id"
        case articleID = "article_id"
    }
    
    // MARK: - Init for creating test/mock data
    public init(name: String, description: String, avatarURL: String, duration: Int, score: Double,
         podcastID: String? = nil, episodeID: String? = nil, episodeCount: Int? = nil,
         language: String? = nil, priority: Int? = nil, popularityScore: Int? = nil,
         podcastName: String? = nil, authorName: String? = nil, seasonNumber: Int? = nil,
         episodeType: String? = nil, number: Int? = nil, audioURL: String? = nil,
         releaseDate: String? = nil, chapters: [String]? = nil, audiobookID: String? = nil,
         articleID: String? = nil) {
        self.name = name
        self.description = description
        self.avatarURL = avatarURL
        self.duration = duration
        self.score = score
        self.podcastID = podcastID
        self.episodeID = episodeID
        self.episodeCount = episodeCount
        self.language = language
        self.priority = priority
        self.popularityScore = popularityScore
        self.podcastName = podcastName
        self.authorName = authorName
        self.seasonNumber = seasonNumber
        self.episodeType = episodeType
        self.number = number
        self.audioURL = audioURL
        self.releaseDate = releaseDate
        self.chapters = chapters
        self.audiobookID = audiobookID
        self.articleID = articleID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        avatarURL = try container.decode(String.self, forKey: .avatarURL)
        duration = try container.decode(Int.self, forKey: .duration)
        
        // Handle score as either Int or Double
        if let scoreInt = try? container.decode(Int.self, forKey: .score) {
            score = Double(scoreInt)
        } else {
            score = try container.decode(Double.self, forKey: .score)
        }
        
        // Optional fields
        podcastID = try container.decodeIfPresent(String.self, forKey: .podcastID)
        episodeID = try container.decodeIfPresent(String.self, forKey: .episodeID)
        episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        popularityScore = try container.decodeIfPresent(Int.self, forKey: .popularityScore)
        podcastName = try container.decodeIfPresent(String.self, forKey: .podcastName)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber)
        episodeType = try container.decodeIfPresent(String.self, forKey: .episodeType)
        number = try container.decodeIfPresent(Int.self, forKey: .number)
        audioURL = try container.decodeIfPresent(String.self, forKey: .audioURL)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        chapters = try container.decodeIfPresent([String].self, forKey: .chapters)
        audiobookID = try container.decodeIfPresent(String.self, forKey: .audiobookID)
        articleID = try container.decodeIfPresent(String.self, forKey: .articleID)
    }
}

// MARK: - Pagination
public struct Pagination: Codable {
    public let nextPage: String?
    public let totalPages: Int
    
    public init(nextPage: String?, totalPages: Int) {
        self.nextPage = nextPage
        self.totalPages = totalPages
    }
    
    enum CodingKeys: String, CodingKey {
        case totalPages = "total_pages"
        case nextPage = "next_page"
    }
}