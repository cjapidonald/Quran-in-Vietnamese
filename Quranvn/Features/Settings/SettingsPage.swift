import AuthenticationServices
import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var readerStore: ReaderStore
    @EnvironmentObject private var cloudAuthManager: CloudAuthManager
    @EnvironmentObject private var quranStore: QuranDataStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var reminderTime = Self.defaultReminderTime
    @State private var isDeletingAccount = false
    @State private var isShowingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?
#if DEBUG
    @State private var isShowingDebugMenu = false
#endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.stack) {
                    accountSection
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
        .task {
            cloudAuthManager.refreshCredentialState()
        }
        .confirmationDialog(
            "Bạn có chắc chắn muốn xóa tài khoản?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Xóa tài khoản", role: .destructive) {
                performAccountDeletion()
            }
            Button("Hủy", role: .cancel) {}
        }
        .alert(
            "Không thể xóa tài khoản",
            isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { newValue in
                    if !newValue {
                        deleteErrorMessage = nil
                    }
                }
            ),
            actions: {
                Button("Đóng", role: .cancel) {}
            },
            message: {
                Text(deleteErrorMessage ?? "Đã xảy ra lỗi không xác định.")
            }
        )
#if DEBUG
        .sheet(isPresented: $isShowingDebugMenu) {
            DebugMenu()
                .environmentObject(appState)
                .environmentObject(readerStore)
                .environmentObject(quranStore)
        }
#endif
    }

    private var accountSection: some View {
        settingsSection(title: "Tài khoản") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(accountStatusColor.opacity(0.15))
                        Image(systemName: "applelogo")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(accountStatusColor)
                    }
                    .frame(width: 44, height: 44)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(cloudAuthManager.isSignedIn ? "Đăng nhập Apple đang bật" : "Đăng nhập Apple chưa được bật"))

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(cloudAuthManager.statusDescription)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(primaryText)

                        Text(cloudAuthManager.isSignedIn ? "Đồng bộ hóa đang hoạt động." : "Đăng nhập để đồng bộ dữ liệu.")
                            .font(.footnote)
                            .foregroundStyle(secondaryText)
                    }

                    Spacer()
                }

                SignInWithAppleButton(.signIn) { request in
                    guard cloudAuthManager.isSignInAvailable else {
                        return
                    }
                    cloudAuthManager.prepareAuthorizationRequest(request)
                } onCompletion: { result in
                    guard cloudAuthManager.isSignInAvailable else {
                        return
                    }
                    cloudAuthManager.handleAuthorization(result: result)
                }
                .disabled(!cloudAuthManager.isSignInAvailable || isDeletingAccount)
                .frame(maxWidth: .infinity, minHeight: 44)
                .glassCard(cornerRadius: DesignTokens.CornerRadius.large)

                if !cloudAuthManager.isSignInAvailable {
                    Text("Chạy ứng dụng trên thiết bị thật đã đăng nhập iCloud để sử dụng Đăng nhập với Apple.")
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                }

                if cloudAuthManager.isSignedIn {
                    Button("Đăng xuất") {
                        cloudAuthManager.signOut()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(isDeletingAccount)

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        if isDeletingAccount {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                ProgressView()
                                Text("Đang xóa…")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Xóa tài khoản")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isDeletingAccount)
                }
            }
        }
    }

    private var appearanceSection: some View {
        settingsSection(title: "Giao diện") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Chủ đề")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)

                Picker("Chủ đề", selection: $appState.themeStyle) {
                    ForEach(AppState.ThemeStyle.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Hiệu ứng nền")
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
                Text("Màu chữ bản dịch")
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
        settingsSection(title: "Kiểu chữ") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Phông chữ tiếng Ả Rập")
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
                Text("Phông chữ tiếng Việt")
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
                    Text("Cỡ chữ")
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
                    Text("Cỡ chữ")
                }
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Xem thử")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("ٱلسَّلَامُ عَلَيْكُمْ")
                        .font(readerStore.arabicFont(for: readerStore.fontSize))
                        .foregroundStyle(primaryText)
                    Text("Đây là đoạn dịch thử nghiệm để xem kích thước chữ.")
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
        settingsSection(title: "Đọc") {
            Toggle(isOn: $readerStore.isFlowMode) {
                Text("Chế độ dạng dòng")
                    .foregroundStyle(primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))

            Toggle(isOn: alwaysArabicBinding) {
                Text("Luôn hiển thị tiếng Ả Rập")
                    .foregroundStyle(primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))
        }
    }

    private var audioSection: some View {
        settingsSection(title: "Âm thanh") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Người đọc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)
                Picker("Người đọc", selection: .constant(reciterOptions.first!)) {
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
                Text("Hiện trình phát mini trong tab Đọc")
                    .foregroundStyle(primaryText)
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))
        }
    }

    private var remindersSection: some View {
        settingsSection(title: "Nhắc nhở") {
            HStack {
                DatePicker(
                    "Thời gian nhắc",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .disabled(true)

                Spacer()

                Text("Sắp ra mắt")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private var aboutSection: some View {
        settingsSection(title: "Giới thiệu") {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Tìm hiểu về các nguồn dữ liệu được sử dụng trong bản thử nghiệm này.")
                    .foregroundStyle(secondaryText)

                NavigationLink {
                    AttributionPage()
                } label: {
                    HStack {
                        Text("Xem nguồn nội dung")
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

    private func performAccountDeletion() {
        isDeletingAccount = true
        deleteErrorMessage = nil

        Task { @MainActor in
            do {
                try await cloudAuthManager.deleteAccount()
            } catch {
                deleteErrorMessage = cloudAuthManager.userFriendlyMessage(for: error)
            }

            isDeletingAccount = false
        }
    }

    private var accountStatusColor: Color {
        cloudAuthManager.isSignedIn ? .green : .red
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
        .environmentObject(CloudAuthManager())
        .environmentObject(QuranDataStore())
}
