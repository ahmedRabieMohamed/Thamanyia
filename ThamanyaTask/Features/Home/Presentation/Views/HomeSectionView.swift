//
//  HomeSectionView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 02/08/2025.
//

import SwiftUI

struct HomeSectionView: View {
    let section: HomeSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: section.name, icon: getIconForSection(section.name))
            
            switch section.type {
            case "square":
                SquareGridView(items: section.content)
            case "2_lines_grid":
                TwoLinesGridView(items: section.content)
            case "big_square":
                BigSquareView(items: section.content)
            case "queue":
                QueueView(items: section.content)
            default:
                SquareGridView(items: section.content)
            }
        }
    }
    
    private func getIconForSection(_ name: String) -> String {
        switch name {
        default:
            return "music.note"
        }
    }
}
