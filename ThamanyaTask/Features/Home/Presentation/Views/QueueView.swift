//
//  QueueView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 02/08/2025.
//

import SwiftUI

struct QueueView: View {
    let items: [SectionContent]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(items.prefix(8)) { item in
                    ContentItemCard(item: item, style: .list)
                        .frame(width: 300)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
