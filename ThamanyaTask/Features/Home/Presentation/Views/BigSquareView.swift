//
//  BigSquareView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 02/08/2025.
//

import SwiftUI

struct BigSquareView: View {
    let items: [SectionContent]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(items.prefix(10)) { item in
                    ContentItemCard(item: item, style: .bigSquare)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
