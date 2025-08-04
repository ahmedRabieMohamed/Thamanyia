//
//  SearchView.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel = {
        let repository: SearchRepositoryProtocol = DIContainer.shared.resolve(SearchRepositoryProtocol.self)
        return SearchViewModel(repository: repository)
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 32) {
                        ForEach(viewModel.searchResults) { section in
                            SearchSectionView(section: section)
                        }
                    }
                    .padding(.top, 16)
                }
                .overlay {
                    if viewModel.searchText.isEmpty {
                        SearchEmptyState()
                    } else if case .loading = viewModel.loadingState {
                        LoadingView(message: "جاري البحث...")
                    } else if case .error(let message) = viewModel.loadingState {
                        ErrorView(message: message) {
                            Task {
                                await viewModel.performSearch()
                            }
                        }
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        NoResultsView(searchText: viewModel.searchText)
                    }
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SearchBar(text: $viewModel.searchText, placeholder: "البحث عن البودكاست والحلقات...")
                }
            }
        }
    }
}

// MARK: - Search Section View
struct SearchSectionView: View {
    let section: SearchSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: section.name, icon: "magnifyingglass")
            
            // Display content in a list layout
            LazyVStack(spacing: 12) {
                ForEach(section.content) { item in
                    SearchResultCard(item: item)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Search Empty State
struct SearchEmptyState: View {
    var body: some View {
        VStack(spacing: 48) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "A1A1A6"))
            
            Text("البحث عن المحتوى")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.white)
            
            Text("ابحث عن البودكاست والحلقات والكتب المسموعة والمزيد")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(hex: "A1A1A6"))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - No Results View
struct NoResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.folder")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "A1A1A6"))
            
            Text("لا توجد نتائج")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.white)
            
            Text("لم يتم العثور على نتائج لـ \"\(searchText)\"")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(hex: "A1A1A6"))
                .multilineTextAlignment(.center)
            
            Text("جرب تعديل مصطلحات البحث")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "A1A1A6"))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Helper Functions

#Preview {
    SearchView()
}
