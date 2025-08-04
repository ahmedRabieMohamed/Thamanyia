//
//  HomeView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel = {
        print("🏠 HomeView: Creating HomeViewModel")
        return HomeViewModel()
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HomeHeaderView()
                
                // Main Content
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(viewModel.sections) { section in
                            Section {
                                // Section Content
                                VStack(spacing: 16) {
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
                                .padding(.bottom, 32)
                                .onAppear {
                                    // Load more when reaching the last section
                                    if section.id == viewModel.sections.last?.id {
                                        Task {
                                            await viewModel.loadMoreSections()
                                        }
                                    }
                                }
                            } header: {
                                SectionHeader(title: section.name, icon: getIconForSection(section.name))
                                    .background(Color.black)
                            }
                        }
                        
                        // Loading indicator for pagination
                        if viewModel.hasMorePages && viewModel.loadingState != .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FFD60A")))
                                .frame(height: 50)
                        }
                    }
                    .padding(.top, 16)
                }
                .background(Color.black)
                .refreshable {
                    print("🔄 HomeView: .refreshable triggered")
                    await viewModel.loadHomeSections()
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .overlay {
                if case .loading = viewModel.loadingState, viewModel.sections.isEmpty {
                    LoadingView(message: "جاري التحميل...")
                } else if case .error(let message) = viewModel.loadingState {
                    ErrorView(message: message) {
                        Task {
                            await viewModel.loadHomeSections()
                        }
                    }
                }
            }
        }
        .onAppear {
            if viewModel.sections.isEmpty {
                Task {
                    await viewModel.loadHomeSections()
                }
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

#Preview {
    HomeView()
}
