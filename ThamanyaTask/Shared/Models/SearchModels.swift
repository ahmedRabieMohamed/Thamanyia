//
//  SearchModels.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - Search Response
public struct SearchResponse: Codable {
    public let sections: [SearchSection]
    
    public init(sections: [SearchSection]) {
        self.sections = sections
    }
}

// MARK: - Search Section
public struct SearchSection: Codable, Identifiable {
    public let id = UUID()
    public let name: String
    public let type: String
    public let contentType: String
    public let order: String
    public let content: [SearchContent]
    
    public init(name: String, type: String, contentType: String, order: String, content: [SearchContent]) {
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

// MARK: - Search Content
public struct SearchContent: Codable, Identifiable {
    public let id = UUID()
    public let podcastID: String
    public let name: String
    public let description: String
    public let avatarURL: String
    public let episodeCount: String
    public let duration: String
    public let language: String?
    public let priority: String
    public let popularityScore: String
    public let score: String
    
    public init(podcastID: String, name: String, description: String, avatarURL: String, 
                episodeCount: String, duration: String, language: String?, 
                priority: String, popularityScore: String, score: String) {
        self.podcastID = podcastID
        self.name = name
        self.description = description
        self.avatarURL = avatarURL
        self.episodeCount = episodeCount
        self.duration = duration
        self.language = language
        self.priority = priority
        self.popularityScore = popularityScore
        self.score = score
    }
    
    enum CodingKeys: String, CodingKey {
        case name, description, duration, language, priority, score
        case podcastID = "podcast_id"
        case avatarURL = "avatar_url"
        case episodeCount = "episode_count"
        case popularityScore = "popularityScore"
    }
}