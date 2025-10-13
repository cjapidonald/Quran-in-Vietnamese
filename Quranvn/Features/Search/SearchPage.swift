import SwiftUI

struct SearchPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchQuery: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeManager
                    .backgroundGradient(style: appState.selectedThemeGradient, for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                        header
                        resultsSection
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.top, DesignTokens.Spacing.xl)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Search")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        close()
                    }
                }
            }
        }
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search the Quran")
        .onChange(of: searchQuery) { _, newValue in
            withAnimation(.easeInOut) {
                appState.isSearchFocused = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }
        .tint(accentColor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Search")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)
            Text("Visualise upcoming search with playful mock data")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    @ViewBuilder
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Results")
                .font(.headline)
                .foregroundStyle(primaryText)

            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Start typing to preview how visual search could feel.")
                        .foregroundStyle(secondaryText)
                    Text("No real search yet — everything here is a placeholder experience.")
                        .font(.footnote)
                        .foregroundStyle(secondaryText.opacity(0.8))
                }
                .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(mockResults) { result in
                        Button {
                            open(result)
                        } label: {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text(result.title)
                                    .font(.headline)
                                    .foregroundStyle(primaryText)
                                Text(result.snippet)
                                    .font(.subheadline)
                                    .foregroundStyle(secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            .glassCard(cornerRadius: DesignTokens.CornerRadius.large, padding: 0, shadowStyle: DesignTokens.Shadow.subtle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var mockResults: [SearchResult] {
        let surah = SurahPlaceholder.examples.first { $0.name.contains("Baqarah") } ?? SurahPlaceholder(name: "Al-Baqarah", index: 2)
        return (0..<10).map { index in
            let ayah = 255 + index
            return SearchResult(
                title: "Al-Baqarah — Ayah \(ayah) (placeholder)",
                snippet: "… placeholder text …",
                destination: ReaderDestination(surah: surah, ayah: ayah)
            )
        }
    }

    private func open(_ result: SearchResult) {
        searchQuery = ""
        appState.isSearchFocused = false
        appState.pendingReaderDestination = result.destination
        appState.selectedTab = .read
        appState.showSurahDashboard = true
        close()
    }

    private func close() {
        withAnimation(.easeInOut) {
            appState.isSearchPresented = false
        }
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: appState.selectedThemeGradient, colorScheme: colorScheme)
    }
}

private struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let snippet: String
    let destination: ReaderDestination
}

#Preview {
    SearchPage()
        .environmentObject(AppState())
}
