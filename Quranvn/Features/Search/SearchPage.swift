import SwiftUI

struct SearchPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var mockQuery: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                header
                searchControls
                resultsPreview
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .background(ThemeManager.backgroundGradient(for: colorScheme).ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Search")
                .font(.largeTitle.bold())
            Text("Explore Surahs, reciters, and more")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var searchControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Button(action: { withAnimation(.easeInOut) { appState.isSearchFocused.toggle() } }) {
                StubButtonLabel(title: appState.isSearchFocused ? "Dismiss Keyboard" : "Focus Search", subtitle: "Simulate focusing the search bar")
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Search Scope")
                    .font(.headline)
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(SearchScope.allCases) { scope in
                        Button(scope.rawValue) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                appState.selectedSearchScope = scope
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(scope == appState.selectedSearchScope ? ThemeManager.accentColor(for: colorScheme) : ThemeManager.cardBackground(for: colorScheme).opacity(0.6))
                        .foregroundStyle(scope == appState.selectedSearchScope ? Color.white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous))
                    }
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Mock Query")
                    .font(.headline)
                TextField("Type something...", text: $mockQuery)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                            .stroke(appState.isSearchFocused ? ThemeManager.accentColor(for: colorScheme) : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: appState.isSearchFocused) { _, newValue in
                        if newValue {
                            mockQuery = ""
                        }
                    }
            }
        }
    }

    private var resultsPreview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Preview")
                .font(.headline)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if mockQuery.isEmpty {
                    Text("Suggestions will appear here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sampleResults, id: \.self) { result in
                        Label(result, systemImage: "text.book.closed")
                            .padding(.vertical, DesignTokens.Spacing.xs)
                    }
                }

                Text("Scope: \(appState.selectedSearchScope.rawValue)")
                    .font(.footnote.weight(.semibold))
                    .padding(.top, DesignTokens.Spacing.md)
            }
            .padding(DesignTokens.Spacing.lg)
            .background(ThemeManager.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.16 : 0.08), radius: DesignTokens.Shadow.subtle.radius, x: DesignTokens.Shadow.subtle.x, y: DesignTokens.Shadow.subtle.y)
        }
    }

    private var sampleResults: [String] {
        ["Al-Fatiha", "Ayat al-Kursi", "Reciter Maher Al-Muaiqly"]
    }
}

#Preview {
    SearchPage()
        .environmentObject(AppState())
}
