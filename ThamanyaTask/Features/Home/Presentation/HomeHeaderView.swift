//
//  HomeHeaderView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation
import SwiftUI

struct HomeHeaderView: View {
    var body: some View {
        HStack {
            // Profile Icon
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.green)

            // Greeting Text and Icon
            HStack {
                Text("Good morning Ahmed")
                    .foregroundColor(.white)
                    .font(.headline)
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
            }

            Spacer()

            // Notification Icon with Badge
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)

                // Red Badge
                Text("1")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Circle().foregroundColor(.red))
                    .offset(x: 10, y: -10)
            }
        }
        .padding()
        //.background(Color(hex: "141520"))
    }
}

#Preview {
    HomeHeaderView()
        .background(Color.black)
}
