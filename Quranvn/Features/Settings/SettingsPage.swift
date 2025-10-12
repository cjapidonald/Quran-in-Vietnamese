import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                header
                preferenceToggles
                typographyControls
                aboutSection
            }
            .padding(DesignTokens.Spacing.xl)
        }
        .background(ThemeManager.backgroundGradient(for: colorScheme).ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Settings")
                .font(.largeTitle.bold())
            Text("Customize your reading experience")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var preferenceToggles: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Button(action: { appState.useSystemTheme.toggle() }) {
                StubButtonLabel(title: appState.useSystemTheme ? "Use Custom Theme" : "Use System Theme", subtitle: "Switch between predefined appearance styles")
            }

            Toggle(isOn: $appState.enableNotifications) {
                Text("Enable notifications (placeholder)")
            }
            .toggleStyle(SwitchToggleStyle(tint: ThemeManager.accentColor(for: colorScheme)))
            .padding()
            .background(ThemeManager.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.16 : 0.08), radius: DesignTokens.Shadow.subtle.radius, x: DesignTokens.Shadow.subtle.x, y: DesignTokens.Shadow.subtle.y)
        }
    }

    private var typographyControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Font Size")
                .font(.headline)

            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(FontSizeOption.allCases) { option in
                    Button(option.rawValue) {
                        withAnimation(.easeInOut) {
                            appState.selectedFontSize = option
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(option == appState.selectedFontSize ? ThemeManager.accentColor(for: colorScheme) : ThemeManager.cardBackground(for: colorScheme).opacity(0.6))
                    .foregroundStyle(option == appState.selectedFontSize ? Color.white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous))
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Preview")
                    .font(.headline)
                Text(sampleText(for: appState.selectedFontSize))
                    .font(font(for: appState.selectedFontSize))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ThemeManager.cardBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.14 : 0.08), radius: DesignTokens.Shadow.subtle.radius, x: DesignTokens.Shadow.subtle.x, y: DesignTokens.Shadow.subtle.y)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("About")
                .font(.headline)
            Text("Version 0.1.0 (placeholder)")
                .foregroundStyle(.secondary)
            Text("Built for studying the Quran in Arabic and Vietnamese with English assistance.")
                .font(.footnote)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(ThemeManager.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.08), radius: DesignTokens.Shadow.subtle.radius, x: DesignTokens.Shadow.subtle.x, y: DesignTokens.Shadow.subtle.y)
    }

    private func font(for option: FontSizeOption) -> Font {
        switch option {
        case .small:
            return .callout
        case .medium:
            return .body
        case .large:
            return .title3
        }
    }

    private func sampleText(for option: FontSizeOption) -> String {
        switch option {
        case .small:
            return "Small sample text for recitation notes."
        case .medium:
            return "Balanced reading size with translation hints."
        case .large:
            return "Large print for comfortable night reading."
        }
    }
}

#Preview {
    SettingsPage()
        .environmentObject(AppState())
}
