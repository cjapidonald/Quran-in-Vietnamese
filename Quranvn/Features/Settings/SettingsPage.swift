import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var reminderTime = Self.defaultReminderTime
#if DEBUG
    @State private var isShowingDebugMenu = false
#endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                    appearanceSection
                    typographySection
                    readingSection
                    audioSection
                    remindersSection
                    aboutSection
                }
                .padding(DesignTokens.Spacing.xl)
            }
            .background(
                ThemeManager
                    .backgroundGradient(style: appState.selectedThemeGradient, for: activeColorScheme)
                    .ignoresSafeArea()
            )
            .tint(accentColor)
            .navigationBarTitleDisplayMode(.inline)
        }
#if DEBUG
        .sheet(isPresented: $isShowingDebugMenu) {
            DebugMenu()
                .environmentObject(appState)
                .environmentObject(readerStore)
        }
#endif
    }

    private var appearanceSection: some View {
        settingsSection(title: "Appearance") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Theme")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)

                Picker("Theme", selection: $appState.themeStyle) {
                    ForEach(AppState.ThemeStyle.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Background gradient")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)

                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(ThemeManager.ThemeGradient.allCases) { option in
                        GradientSwatch(
                            gradient: option,
                            isSelected: option == appState.selectedThemeGradient
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                appState.selectedThemeGradient = option
                                readerStore.selectGradient(option)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Translation text color")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)

                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(ReaderStore.TextColorStyle.allCases, id: \.self) { style in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                readerStore.selectTextColorStyle(style)
                            }
                        } label: {
                            colorChip(for: style)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var typographySection: some View {
        settingsSection(title: "Typography") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Arabic font")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(ReaderStore.ArabicFontOption.allCases) { option in
                        SegmentPill(
                            title: option.displayName,
                            isSelected: option == readerStore.arabicFontSelection,
                            theme: appState.selectedThemeGradient
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                readerStore.arabicFontSelection = option
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Vietnamese / English font")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(ReaderStore.TranslationFontOption.allCases) { option in
                        SegmentPill(
                            title: option.displayName,
                            isSelected: option == readerStore.translationFontSelection,
                            theme: appState.selectedThemeGradient
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                readerStore.translationFontSelection = option
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Text("Font size")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(secondaryText)
                    Spacer()
                    Text("\(Int(readerStore.fontSize)) pt")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(secondaryText)
                }

                Slider(
                    value: Binding(
                        get: { readerStore.fontSize },
                        set: { newValue in
                            readerStore.fontSize = newValue
                        }
                    ),
                    in: 16...28,
                    step: 1
                ) {
                    Text("Font size")
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Preview")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("ٱلسَّلَامُ عَلَيْكُمْ")
                        .font(readerStore.arabicFont(for: readerStore.fontSize))
                        .foregroundStyle(primaryText)
                    Text("Đây là đoạn dịch thử nghiệm để xem kích thước chữ.")
                        .font(readerStore.translationFont(for: readerStore.fontSize))
                        .foregroundStyle(secondaryText)
                    Text("This is a placeholder English translation preview.")
                        .font(readerStore.translationFont(for: readerStore.fontSize))
                        .foregroundStyle(secondaryText)
                }
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .glassCard(cornerRadius: DesignTokens.CornerRadius.large)
            }
        }
    }

    private var readingSection: some View {
        settingsSection(title: "Reading") {
            Toggle(isOn: $readerStore.isFlowMode) {
                Text("Flow mode")
                    .foregroundStyle(primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))

            Toggle(isOn: alwaysArabicBinding) {
                Text("Always show Arabic")
                    .foregroundStyle(primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))
        }
    }

    private var audioSection: some View {
        settingsSection(title: "Audio") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Reciter")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)
                Picker("Reciter", selection: .constant(reciterOptions.first!)) {
                    ForEach(reciterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .disabled(true)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(secondaryText.opacity(0.2), lineWidth: 1)
                )
                .opacity(0.6)
            }

            Toggle(isOn: $appState.showMiniPlayer) {
                Text("Mini player on Read page")
                    .foregroundStyle(primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))
        }
    }

    private var remindersSection: some View {
        settingsSection(title: "Reminders") {
            HStack {
                DatePicker(
                    "Reminder time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .disabled(true)

                Spacer()

                Text("Coming soon")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private var aboutSection: some View {
        settingsSection(title: "About") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Learn about the sources used in this preview app.")
                    .foregroundStyle(secondaryText)

                NavigationLink {
                    AttributionPage()
                } label: {
                    HStack {
                        Text("View content attributions")
                            .foregroundStyle(primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium, style: .continuous)
                            .fill(ThemeManager.semanticColor(.accent, for: appState.selectedThemeGradient, colorScheme: activeColorScheme).opacity(0.15))
                    )
                }
            }
        }
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title)
                .font(.headline)
                .foregroundStyle(primaryText)
            content()
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .glassCard(cornerRadius: DesignTokens.CornerRadius.extraLarge)
    }

    private func colorChip(for style: ReaderStore.TextColorStyle) -> some View {
        let isSelected = style == readerStore.selectedTextColorStyle
        let color = readerStore.translationTextColor(
            for: style,
            colorScheme: activeColorScheme,
            gradient: appState.selectedThemeGradient
        )

        return Circle()
            .fill(color)
            .frame(width: 44, height: 44)
            .overlay(
                Circle()
                    .stroke(isSelected ? accentColor : Color.white.opacity(0.35), lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: color.opacity(0.25), radius: isSelected ? 8 : 4)
    }

    private var alwaysArabicBinding: Binding<Bool> {
        Binding(
            get: { readerStore.showArabic },
            set: { newValue in
                readerStore.showArabic = newValue
                readerStore.ensureNonEmptyLanguages()
            }
        )
    }

    private var activeColorScheme: ColorScheme {
        appState.themeStyle.resolvedColorScheme(for: colorScheme)
    }

    private var primaryText: Color {
        ThemeManager.semanticColor(.primary, for: appState.selectedThemeGradient, colorScheme: activeColorScheme)
    }

    private var secondaryText: Color {
        ThemeManager.semanticColor(.secondary, for: appState.selectedThemeGradient, colorScheme: activeColorScheme)
    }

    private var accentColor: Color {
        ThemeManager.accentColor(for: appState.selectedThemeGradient, colorScheme: activeColorScheme)
    }

    private var reciterOptions: [String] {
        ["Mishary Rashid Alafasy"]
    }

    private static var defaultReminderTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

#Preview {
    SettingsPage()
        .environmentObject(AppState())
        .environmentObject(ReaderStore())
}
