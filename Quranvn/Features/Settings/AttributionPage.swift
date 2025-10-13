import SwiftUI

struct AttributionPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                Text("Nguồn nội dung")
                    .font(.largeTitle.bold())
                    .foregroundStyle(primaryText)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    attributionRow(title: "Nguồn văn bản Ả Rập…")
                    attributionRow(title: "Nguồn bản dịch tiếng Việt…")
                    attributionRow(title: "Nguồn âm thanh…")
                }
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .background(
            ThemeManager
                .backgroundGradient(style: appState.selectedThemeGradient, for: activeColorScheme)
                .ignoresSafeArea()
        )
        .navigationTitle("Nguồn trích dẫn")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func attributionRow(title: String) -> some View {
        Text(title)
            .font(.body.weight(.medium))
            .foregroundStyle(primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .glassCard(cornerRadius: DesignTokens.CornerRadius.large)
    }

    private var activeColorScheme: ColorScheme {
        appState.themeStyle.resolvedColorScheme(for: colorScheme)
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: appState.selectedThemeGradient, colorScheme: activeColorScheme)
    }
}

#Preview {
    AttributionPage()
        .environmentObject(AppState())
}
