import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                header
                preferenceToggles
                gradientSelection
                typographyControls
                aboutSection
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
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)
            Text("Customize your reading experience")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var preferenceToggles: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            PrimaryButton(
                title: appState.useSystemTheme ? "Use Custom Theme" : "Use System Theme",
                subtitle: "Switch between predefined appearance styles",
                icon: "paintbrush.pointed",
                theme: appState.selectedThemeGradient
            ) {
                appState.useSystemTheme.toggle()
            }

            Toggle(isOn: $appState.enableNotifications) {
                Text("Enable notifications (placeholder)")
                    .foregroundStyle(primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))
            .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
        }
    }

    private var gradientSelection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Background Gradient")
                .font(.headline)
                .foregroundStyle(primaryText)

            HStack(spacing: DesignTokens.Spacing.lg) {
                ForEach(ThemeManager.ThemeGradient.allCases) { option in
                    GradientSwatch(
                        gradient: option,
                        isSelected: option == appState.selectedThemeGradient
                    ) {
                        withAnimation(.easeInOut) {
                            appState.selectedThemeGradient = option
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private var typographyControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Font Size")
                .font(.headline)
                .foregroundStyle(primaryText)

            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(FontSizeOption.allCases) { option in
                    SegmentPill(
                        title: option.rawValue,
                        isSelected: option == appState.selectedFontSize,
                        theme: appState.selectedThemeGradient
                    ) {
                        withAnimation(.easeInOut) {
                            appState.selectedFontSize = option
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Preview")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                Text(sampleText(for: appState.selectedFontSize))
                    .font(font(for: appState.selectedFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("About")
                .font(.headline)
                .foregroundStyle(primaryText)
            Text("Version 0.1.0 (placeholder)")
                .foregroundStyle(secondaryText)
            Text("Built for studying the Quran in Arabic and Vietnamese with English assistance.")
                .font(.footnote)
                .foregroundStyle(secondaryText)
        }
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
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
    SettingsPage()
        .environmentObject(AppState())
}
