import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum AppTheme {
    static let backgroundTop = Color(red: 0.08, green: 0.10, blue: 0.14)
    static let backgroundBottom = Color(red: 0.16, green: 0.20, blue: 0.26)
    static let card = Color(red: 0.14, green: 0.18, blue: 0.24)
    static let cardHighlight = Color(red: 0.18, green: 0.22, blue: 0.29)
    static let accent = Color(red: 0.90, green: 0.72, blue: 0.28)
    static let accentSoft = Color(red: 0.30, green: 0.38, blue: 0.48)
    static let text = Color(red: 0.92, green: 0.95, blue: 0.98)
    static let muted = Color(red: 0.70, green: 0.76, blue: 0.82)
    static let bezelDark = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let bezelLight = Color.white.opacity(0.08)
    static let gridLine = Color.white.opacity(0.06)
}

enum MainMenuConfig {
    static let logoBase64Key = "mainMenuLogoBase64"
    static let titleKey = "mainMenuTitle"
    static let subtitleKey = "mainMenuSubtitle"
    static let descriptionKey = "mainMenuDescription"

    static let defaultTitle = "Piper M600/SLS"
    static let defaultSubtitle = "Main Menu"
    static let defaultDescription = "This application calculates aircraft loading and verifies compliance with weight and balance limitations, with graphical and numerical results. It includes an integrated checklist for Piper M600 procedures, POH access by keyword and subject, document storage for flight crew, aircraft, and company operations, and a cockpit scratchpad for pilot convenience."
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            RootMenuView()
        }
    }
}

struct BrandLogoView: View {
    @AppStorage(MainMenuConfig.logoBase64Key) private var mainMenuLogoBase64: String = ""
    private let fallbackAssetName: String

    init(fallbackAssetName: String = "Logo") {
        self.fallbackAssetName = fallbackAssetName
    }

    var body: some View {
        if
            let data = Data(base64Encoded: mainMenuLogoBase64),
            !data.isEmpty,
            let uiImage = UIImage(data: data)
        {
            Image(uiImage: uiImage)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
        } else {
            Image(fallbackAssetName)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
        }
    }
}

struct RootMenuView: View {
    @StateObject private var store = ChecklistStore()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(MainMenuConfig.logoBase64Key) private var mainMenuLogoBase64: String = ""
    @AppStorage(MainMenuConfig.titleKey) private var mainMenuTitle: String = MainMenuConfig.defaultTitle
    @AppStorage(MainMenuConfig.descriptionKey) private var mainMenuDescription: String = MainMenuConfig.defaultDescription

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var columns: [GridItem] {
        let spacing: CGFloat = isPadLayout ? 16 : 10
        return [
            GridItem(.flexible(), spacing: spacing, alignment: .top),
            GridItem(.flexible(), spacing: spacing, alignment: .top)
        ]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: isPadLayout ? 12 : 10) {
                rootHeader
                LazyVGrid(columns: columns, spacing: isPadLayout ? 16 : 10) {
                    NavigationLink {
                        ChecklistHomeView(store: store)
                    } label: {
                        MenuCardView(
                            title: "Checklist",
                            subtitle: "\(store.sections.count) sections",
                            systemImage: "checklist"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ScratchpadView()
                    } label: {
                        MenuCardView(
                            title: "Scratchpad",
                            subtitle: "Freehand notes and quick sketches",
                            systemImage: "pencil.and.scribble"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        DocumentsView()
                    } label: {
                        MenuCardView(
                            title: "Documents",
                            subtitle: "Access Personal, Aircraft and Company documents",
                            systemImage: "doc.text.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        WeightBalanceInputView()
                    } label: {
                        MenuCardView(
                            title: "Weight & Balance",
                            subtitle: "Verify the aircraft loading is within limits for safe flight",
                            systemImage: "scalemass.fill"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        POHView()
                    } label: {
                        MenuCardView(
                            title: "POH",
                            subtitle: "POH reference and search",
                            systemImage: "airplane"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        G3000View()
                    } label: {
                        MenuCardView(
                            title: "Avionics Guide",
                            subtitle: "Avionics reference and search",
                            systemImage: "gauge"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, isPadLayout ? 22 : 14)
                .padding(.bottom, isPadLayout ? 18 : 14)

                weatherTestButton
                boardingPassButton
            }
            .padding(.top, isPadLayout ? 10 : 6)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(InstrumentBackground().ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MainMenuSetupView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppTheme.accent)
                }
                .accessibilityLabel("Main Menu Setup")
            }
        }
    }

    private var rootHeader: some View {
        VStack(spacing: isPadLayout ? 12 : 8) {
            BrandLogoView()
                .frame(maxWidth: isPadLayout ? 180 : 120)
                .padding(.top, isPadLayout ? 10 : 4)

            Text(mainMenuTitle)
                .font(.custom("Avenir Next Condensed Demi Bold", size: isPadLayout ? 28 : 22))
                .tracking(0.2)
                .foregroundColor(AppTheme.text)

            Text(mainMenuDescription)
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 12 : 10))
                .foregroundColor(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, isPadLayout ? 40 : 20)
                .padding(.bottom, isPadLayout ? 24 : 18)
        }
        .padding(.horizontal, isPadLayout ? 22 : 14)
    }

    private var weatherTestButton: some View {
        NavigationLink {
            WeatherTestView()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: isPadLayout ? 20 : 18, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
                Text("Weather")
                    .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 17 : 15))
                    .foregroundColor(AppTheme.text)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(AppTheme.cardHighlight.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.accentSoft, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, isPadLayout ? 22 : 16)
    }

    private var boardingPassButton: some View {
        NavigationLink {
            BoardingPassBuilderView()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "ticket.fill")
                    .font(.system(size: isPadLayout ? 20 : 18, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
                Text("Boarding Pass")
                    .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 17 : 15))
                    .foregroundColor(AppTheme.text)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(AppTheme.cardHighlight.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.accentSoft, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, isPadLayout ? 22 : 16)
    }
}

struct MainMenuSetupView: View {
    @AppStorage(MainMenuConfig.logoBase64Key) private var mainMenuLogoBase64: String = ""
    @AppStorage(MainMenuConfig.titleKey) private var mainMenuTitle: String = MainMenuConfig.defaultTitle
    @AppStorage(MainMenuConfig.subtitleKey) private var mainMenuSubtitle: String = MainMenuConfig.defaultSubtitle
    @AppStorage(MainMenuConfig.descriptionKey) private var mainMenuDescription: String = MainMenuConfig.defaultDescription
    @AppStorage("editPasscode") private var editPasscode: String = ""

    @State private var showLogoImporter = false
    @State private var showLogoImportError = false
    @State private var logoImportErrorMessage = ""
    @State private var isUnlocked = false
    @State private var showUnlockPopup = false
    @State private var unlockInput = ""
    @State private var newPasscodeInput = ""
    @State private var unlockError: String?
    @State private var showResetAcknowledgment = false

    private var isEditingLocked: Bool {
        !isUnlocked
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    BrandLogoView()
                        .frame(maxWidth: 180, maxHeight: 140)
                    Spacer()
                }

                if let dimensionsText = logoDimensionsText {
                    Text("Current image size: \(dimensionsText)")
                        .font(.custom("Avenir Next Regular", size: 12))
                        .foregroundColor(AppTheme.muted)
                }

                Button("Choose Logo From Files") {
                    if isEditingLocked {
                        presentUnlockPrompt()
                    } else {
                        showLogoImporter = true
                    }
                }
            } header: {
                Text("Main Menu Logo")
            } footer: {
                Text("The selected logo appears at the top of the main menu.")
            }

            Section {
                Text("Use PNG or JPEG. A square image works best.\nRecommended size: 1024 x 1024 px.\nMinimum size: 400 x 400 px.\nKeep file size under 5 MB for smooth loading.\nIf text is part of the logo, keep it inside the center 80% area so it is not clipped.")
                    .font(.custom("Avenir Next Regular", size: 12))
                    .foregroundColor(AppTheme.muted)
            } header: {
                Text("Logo Requirements")
            }

            Section {
                lockableField {
                    TextField("Title under logo", text: $mainMenuTitle)
                }
            } header: {
                Text("Main Menu Header")
            } footer: {
                Text("This field shows the current value and updates the main menu immediately.")
            }

            Section {
                lockableField {
                    TextEditor(text: $mainMenuDescription)
                        .frame(minHeight: 160)
                        .foregroundColor(AppTheme.text)
                        .scrollContentBackground(.hidden)
                }
            } header: {
                Text("Main Menu Description")
            } footer: {
                Text("Edit the explanatory text shown below the header.")
            }

            Section {
                Button(role: .destructive) {
                    if isEditingLocked {
                        presentUnlockPrompt()
                    } else {
                        resetMainMenuDefaults()
                        showResetAcknowledgmentBanner()
                    }
                } label: {
                    Text("Reset Defaults")
                }
            } footer: {
                Text("Restores logo, main menu header, and description to default values.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("Main Menu Setup")
        .onAppear {
            isUnlocked = false
        }
        .fileImporter(isPresented: $showLogoImporter, allowedContentTypes: [.image]) { result in
            handleLogoImport(result)
        }
        .alert("Logo Import Error", isPresented: $showLogoImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(logoImportErrorMessage)
        }
        .overlay {
            ZStack(alignment: .top) {
                if showResetAcknowledgment {
                    resetAcknowledgmentBanner
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showUnlockPopup {
                    unlockOverlay
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showResetAcknowledgment)
    }

    private var logoDimensionsText: String? {
        guard
            let data = Data(base64Encoded: mainMenuLogoBase64),
            let uiImage = UIImage(data: data)
        else {
            return nil
        }
        return "\(Int(uiImage.size.width)) x \(Int(uiImage.size.height)) px"
    }

    @ViewBuilder
    private func lockableField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            content()
                .disabled(isEditingLocked)
            if isEditingLocked {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        presentUnlockPrompt()
                    }
            }
        }
    }

    private func presentUnlockPrompt() {
        unlockInput = ""
        newPasscodeInput = ""
        unlockError = nil
        showUnlockPopup = true
    }

    private func handleUnlockSubmit() {
        if editPasscode.isEmpty {
            let trimmed = newPasscodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                unlockError = "Enter a new passcode."
                return
            }
            editPasscode = trimmed
            isUnlocked = true
            showUnlockPopup = false
            unlockError = nil
            return
        }

        if unlockInput == editPasscode {
            isUnlocked = true
            showUnlockPopup = false
            unlockError = nil
        } else {
            unlockError = "Incorrect passcode."
        }
    }

    private var unlockOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    showUnlockPopup = false
                    unlockError = nil
                }

            VStack(alignment: .leading, spacing: 10) {
                Text("Are you sure?")
                    .font(.custom("Avenir Next Demi Bold", size: 16))
                    .foregroundColor(AppTheme.text)

                if editPasscode.isEmpty {
                    Text("No passcode is set. Enter a new passcode to unlock main menu setup editing.")
                        .font(.custom("Avenir Next Regular", size: 13))
                        .foregroundColor(AppTheme.muted)

                    SecureField("New Passcode", text: $newPasscodeInput)
                        .textContentType(.newPassword)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.backgroundTop.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                                )
                        )
                        .foregroundColor(AppTheme.text)
                } else {
                    Text("Enter passcode to unlock main menu setup editing.")
                        .font(.custom("Avenir Next Regular", size: 13))
                        .foregroundColor(AppTheme.muted)

                    SecureField("Passcode", text: $unlockInput)
                        .textContentType(.password)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.backgroundTop.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                                )
                        )
                        .foregroundColor(AppTheme.text)
                }

                if let unlockError {
                    Text(unlockError)
                        .font(.custom("Avenir Next Regular", size: 12))
                        .foregroundColor(.red)
                }

                HStack(spacing: 10) {
                    Button("Cancel") {
                        showUnlockPopup = false
                        unlockError = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.cardHighlight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                            )
                    )
                    .foregroundColor(AppTheme.text)

                    Button(editPasscode.isEmpty ? "Set & Unlock" : "Unlock") {
                        handleUnlockSubmit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.bezelLight, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
    }

    private var resetAcknowledgmentBanner: some View {
        Text("Data have been reset")
            .font(.custom("Avenir Next Demi Bold", size: 13))
            .foregroundColor(AppTheme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accentSoft, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private func showResetAcknowledgmentBanner() {
        showResetAcknowledgment = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showResetAcknowledgment = false
        }
    }

    private func resetMainMenuDefaults() {
        mainMenuLogoBase64 = ""
        mainMenuTitle = MainMenuConfig.defaultTitle
        mainMenuSubtitle = MainMenuConfig.defaultSubtitle
        mainMenuDescription = MainMenuConfig.defaultDescription
    }

    private func handleLogoImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else {
            if case .failure(let error) = result {
                logoImportErrorMessage = error.localizedDescription
                showLogoImportError = true
            }
            return
        }

        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let imageData = try Data(contentsOf: url)
            guard imageData.count <= 5_000_000 else {
                throw NSError(
                    domain: "MainMenuSetup",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "The selected file is larger than 5 MB."]
                )
            }

            guard let image = UIImage(data: imageData) else {
                throw NSError(
                    domain: "MainMenuSetup",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "The selected file is not a valid image."]
                )
            }

            guard image.size.width >= 400, image.size.height >= 400 else {
                throw NSError(
                    domain: "MainMenuSetup",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "The image is too small. Minimum size is 400 x 400 px."]
                )
            }

            mainMenuLogoBase64 = imageData.base64EncodedString()
        } catch {
            logoImportErrorMessage = error.localizedDescription
            showLogoImportError = true
        }
    }
}

struct ChecklistHomeView: View {
    @ObservedObject var store: ChecklistStore
    @State private var showResetAlert = false
    @State private var showResetAcknowledgment = false
    @AppStorage("tailNumber") private var tailNumber: String = ""
    @AppStorage(MainMenuConfig.titleKey) private var mainMenuTitle: String = MainMenuConfig.defaultTitle
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var columns: [GridItem] {
        let minWidth: CGFloat = isPadLayout ? 280 : 180
        let spacing: CGFloat = isPadLayout ? 20 : 12
        return [GridItem(.adaptive(minimum: minWidth), spacing: spacing, alignment: .top)]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: isPadLayout ? 16 : 12) {
                header
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(store.sections.indices, id: \.self) { index in
                        NavigationLink {
                            ChecklistSectionView(section: binding(for: index), store: store)
                        } label: {
                            SectionCardView(section: store.sections[index])
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, isPadLayout ? 28 : 16)
                .padding(.bottom, isPadLayout ? 28 : 20)
            }
            .padding(.top, isPadLayout ? 16 : 8)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(InstrumentBackground().ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showResetAlert = true
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .foregroundColor(AppTheme.accent)
                }
                .accessibilityLabel("Reset Progress")

                NavigationLink {
                    SettingsView(store: store)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .alert("Reset progress?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetProgress()
                showResetAcknowledgmentBanner()
            }
        } message: {
            Text("This clears all checkmarks but keeps your checklist edits.")
        }
        .overlay(alignment: .top) {
            if showResetAcknowledgment {
                resetAcknowledgmentBanner
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showResetAcknowledgment)
    }

    private var header: some View {
        VStack(spacing: isPadLayout ? 14 : 10) {
            BrandLogoView()
                .frame(maxWidth: isPadLayout ? 200 : 132)
                .padding(.top, isPadLayout ? 10 : 4)

            Text(headerTitle)
                .font(.custom("Avenir Next Condensed Demi Bold", size: isPadLayout ? 28 : 22))
                .tracking(0.2)
                .foregroundColor(AppTheme.text)

        }
        .padding(.horizontal, isPadLayout ? 28 : 16)
    }

    private var headerTitle: String {
        let baseTitle = mainMenuTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? MainMenuConfig.defaultTitle
            : mainMenuTitle
        let cleaned = tailNumber
            .uppercased()
            .filter { $0.isNumber || $0.isLetter }
        if cleaned.isEmpty {
            return baseTitle
        }
        return "\(baseTitle) - \(cleaned)"
    }

    private func binding(for index: Int) -> Binding<ChecklistSection> {
        Binding(
            get: { store.sections[index] },
            set: { newValue in
                store.sections[index] = newValue
                store.save()
            }
        )
    }

    private var resetAcknowledgmentBanner: some View {
        Text("Data have been reset")
            .font(.custom("Avenir Next Demi Bold", size: 13))
            .foregroundColor(AppTheme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accentSoft, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private func showResetAcknowledgmentBanner() {
        showResetAcknowledgment = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showResetAcknowledgment = false
        }
    }
}

struct MenuCardView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        let titleHeight: CGFloat = isPadLayout ? 48 : 42
        let subtitleHeight: CGFloat = isPadLayout ? 36 : 34
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: systemImage)
                    .font(.system(size: isPadLayout ? 26 : 22, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: isPadLayout ? 40 : 32, height: isPadLayout ? 40 : 32)
                    .background(
                        Circle()
                            .fill(AppTheme.cardHighlight)
                    )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: isPadLayout ? 16 : 14, weight: .semibold))
                    .foregroundColor(AppTheme.muted)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.custom("Avenir Next Condensed Demi Bold", size: isPadLayout ? 20 : 17))
                    .foregroundColor(AppTheme.text)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(height: titleHeight, alignment: .topLeading)

                Text(subtitle)
                    .font(.custom("Avenir Next Regular", size: isPadLayout ? 14 : 12))
                    .foregroundColor(AppTheme.muted)
                    .lineLimit(3)
                    .frame(height: subtitleHeight, alignment: .topLeading)
            }
        }
        .padding(isPadLayout ? 18 : 14)
        .frame(maxWidth: .infinity, minHeight: isPadLayout ? 120 : 140, maxHeight: isPadLayout ? 130 : 140, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.card, AppTheme.cardHighlight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.bezelDark, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 1)
                .stroke(AppTheme.bezelLight, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}
struct SectionCardView: View {
    let section: ChecklistSection
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLayout ? 10 : 8) {
            Text(section.title)
                .font(.custom("Avenir Next Condensed Demi Bold", size: isPadLayout ? 20 : 17))
                .foregroundColor(AppTheme.text)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            Text("\(section.items.count) item\(section.items.count == 1 ? "" : "s")")
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 14 : 12))
                .foregroundColor(AppTheme.muted)
        }
        .padding(isPadLayout ? 16 : 12)
        .frame(maxWidth: .infinity, minHeight: isPadLayout ? 120 : 88, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.card, AppTheme.cardHighlight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.bezelDark, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 1)
                .stroke(AppTheme.bezelLight, lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
    }
}

struct ChecklistSectionView: View {
    @Binding var section: ChecklistSection
    @ObservedObject var store: ChecklistStore
    @Environment(\.dismiss) private var dismiss
    private let haptics = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(section.title)
                    .font(.custom("Avenir Next Condensed Demi Bold", size: 24))
                    .foregroundColor(AppTheme.text)
                    .multilineTextAlignment(.center)

                Text("\(checkedCount) of \(section.items.count) completed")
                    .font(.custom("Avenir Next Regular", size: 14))
                    .foregroundColor(AppTheme.muted)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(section.items.indices, id: \.self) { index in
                                Color.clear
                                    .frame(height: 1)
                                    .id(anchorID(for: index))

                                Button {
                                    toggleItem(at: index, scrollProxy: proxy)
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(section.items[index].text)
                                                .font(.custom("Avenir Next Demi Bold", size: 18))
                                                .foregroundColor(AppTheme.text)
                                                .multilineTextAlignment(.leading)

                                            Text(section.items[index].isChecked ? "Confirmed" : "Tap to Confirm")
                                                .font(.custom("Avenir Next Regular", size: 13))
                                                .foregroundColor(AppTheme.accent)
                                        }

                                        Spacer()

                                        Image(systemName: section.items[index].isChecked ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundColor(section.items[index].isChecked ? AppTheme.accent : AppTheme.accentSoft)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        LinearGradient(
                                            colors: [AppTheme.card, AppTheme.cardHighlight],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(18)
                                    .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(AppTheme.bezelDark, lineWidth: 1)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .inset(by: 1)
                                            .stroke(AppTheme.bezelLight, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
            .padding(.top, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var checkedCount: Int {
        section.items.filter { $0.isChecked }.count
    }

    private func toggleItem(at index: Int, scrollProxy: ScrollViewProxy) {
        haptics.impactOccurred()
        section.items[index].isChecked.toggle()
        store.save()

        let isLastItem = index == section.items.count - 1
        let allChecked = section.items.allSatisfy { $0.isChecked }
        if isLastItem && allChecked {
            dismiss()
            return
        }

        if section.items[index].isChecked && !isLastItem {
            let nextIndex = index + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    scrollProxy.scrollTo(anchorID(for: nextIndex), anchor: .top)
                }
            }
        }
    }

    private func anchorID(for index: Int) -> String {
        "item-anchor-\(index)"
    }
}

struct InstrumentBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { _ in
                Canvas { context, size in
                    let step: CGFloat = 28
                    var path = Path()

                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += step
                    }

                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += step
                    }

                    context.stroke(path, with: .color(AppTheme.gridLine), lineWidth: 0.6)
                }
                .opacity(0.35)
                .blendMode(.screen)
            }
        }
    }
}
