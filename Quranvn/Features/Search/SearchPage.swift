import SwiftUI

struct SearchPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var mockQuery: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                header
                searchControls
                resultsPreview
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .background(
            ThemeManager
                .backgroundGradient(style: appState.selectedThemeGradient, for: colorScheme)
                .ignoresSafeArea()
        )
        .tint(accentColor)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Search")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)
            Text("Explore Surahs, reciters, and more")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var searchControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            PrimaryButton(
                title: appState.isSearchFocused ? "Dismiss Keyboard" : "Focus Search",
                subtitle: "Simulate focusing the search bar",
                icon: "magnifyingglass",
                theme: appState.selectedThemeGradient
            ) {
                withAnimation(.easeInOut) { appState.isSearchFocused.toggle() }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Search Scope")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(SearchScope.allCases) { scope in
                        SegmentPill(
                            title: scope.rawValue,
                            isSelected: scope == appState.selectedSearchScope,
                            theme: appState.selectedThemeGradient
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                appState.selectedSearchScope = scope
                            }
                        }
                    }
                }
            }
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Mock Query")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                TextField("Type something...", text: $mockQuery)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge, padding: DesignTokens.Spacing.sm, shadowStyle: DesignTokens.Shadow.subtle)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge, style: .continuous)
                            .strokeBorder(appState.isSearchFocused ? accentColor.opacity(0.7) : Color.white.opacity(colorScheme == .dark ? 0.15 : 0.3), lineWidth: 1)
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut) { appState.isSearchFocused = true }
                    }
                    .onChange(of: appState.isSearchFocused) { _, newValue in
                        if newValue {
                            mockQuery = ""
                        }
                    }
            }
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
        }
    }

    private var resultsPreview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(primaryText)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if mockQuery.isEmpty {
                    Text("Suggestions will appear here.")
                        .foregroundStyle(secondaryText)
                } else {
                    ForEach(sampleResults, id: \.self) { result in
                        Label(result, systemImage: "text.book.closed")
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .foregroundStyle(primaryText)
                    }
                }

                Text("Scope: \(appState.selectedSearchScope.rawValue)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(secondaryText)
                    .padding(.top, DesignTokens.Spacing.md)
            }
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
        }
    }

    private var sampleResults: [String] {
        ["Al-Fatiha", "Ayat al-Kursi", "Reciter Maher Al-Muaiqly"]
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

#Preview {
    SearchPage()
        .environmentObject(AppState())
}
