//
//  TwoLinesGridView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 02/08/2025.
//

import SwiftUI

struct TwoLinesGridView: View {
    let items: [SectionContent]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(
                rows: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 15
            ) {
                ForEach(items.prefix(10)) { item in
                    ContentItemCard(item: item, style: .twoLines)
                        .cornerRadius(15)
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
        }
    }
}
