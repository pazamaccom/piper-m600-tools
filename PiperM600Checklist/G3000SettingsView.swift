import SwiftUI
import UniformTypeIdentifiers

struct G3000SettingsView: View {
    @AppStorage("default_docs_access_code") private var accessCode = ""
    @AppStorage(G3000GuideConfig.titleKey) private var guideTitle: String = G3000GuideConfig.defaultTitle
    @State private var showRebuildConfirm = false
    @State private var showRebuildResult = false
    @State private var rebuildMessage = ""
    @State private var showImporter = false
    @State private var showDeleteConfirm = false
    @State private var showReplaceConfirm = false
    @State private var showReplaceConfirmForDownload = false
    @State private var statusMessage = ""
    @State private var showStatusAlert = false
    @State private var isDownloading = false
    @State private var hasLocalFile = DocumentStorage.exists(.g3000)
    @State private var metaInfo = DocumentStorage.meta(for: .g3000)

    private var documentFooterText: String {
        if hasLocalFile, let metaInfo {
            return "Installed (\(formattedSize(metaInfo.size))), updated \(formattedDate(metaInfo.date))."
        }
        if hasLocalFile {
            return "Local Avionics PDF is installed."
        }
        return "No Avionics PDF loaded."
    }

    var body: some View {
        List {
            displaySection
            documentSection
            defaultSection
            rebuildSection
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("Avionics Guide Settings")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf]) { result in
            handleImport(result)
        }
        .alert("Rebuild Avionics Index?", isPresented: $showRebuildConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Rebuild", role: .destructive) {
                let success = G3000IndexCache.clear()
                rebuildMessage = success
                    ? "Avionics guide index cleared. It will rebuild next time you open Avionics Guide."
                    : "Could not clear the Avionics guide index. Please try again."
                showRebuildResult = true
            }
        } message: {
            Text("This clears the cached Avionics guide index and forces a rebuild.")
        }
        .alert("Avionics Index", isPresented: $showRebuildResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(rebuildMessage)
        }
        .alert("Avionics Document", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
        .alert("Remove Avionics PDF?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if DocumentStorage.delete(.g3000) {
                    hasLocalFile = false
                    metaInfo = nil
                    _ = G3000IndexCache.clear()
                    statusMessage = "Avionics PDF removed."
                } else {
                    statusMessage = "Could not remove the Avionics PDF."
                }
                showStatusAlert = true
            }
        } message: {
            Text("This removes the locally stored Avionics PDF.")
        }
        .alert("Replace Avionics PDF?", isPresented: $showReplaceConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Replace", role: .destructive) {
                showImporter = true
            }
        } message: {
            Text("This will replace the current Avionics PDF.")
        }
        .alert("Replace Avionics PDF?", isPresented: $showReplaceConfirmForDownload) {
            Button("Cancel", role: .cancel) {}
            Button("Replace", role: .destructive) {
                Task { await downloadDefault() }
            }
        } message: {
            Text("This will replace the current Avionics PDF with the default document.")
        }
    }

    private var displaySection: some View {
        Section {
            TextField("Guide name", text: $guideTitle)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
        } header: {
            Text("Display")
        } footer: {
            Text("Shown as the title on the Avionics guide page.")
        }
    }

    private var documentSection: some View {
        Section {
            Button("Load Avionics PDF") {
                if hasLocalFile {
                    showReplaceConfirm = true
                } else {
                    showImporter = true
                }
            }
            .disabled(isDownloading)

            Button {
                showDeleteConfirm = true
            } label: {
                Text("Remove Local Avionics PDF")
                    .foregroundColor(hasLocalFile ? .red : .secondary)
            }
            .disabled(!hasLocalFile || isDownloading)
        } header: {
            Text("Document")
        } footer: {
            Text(documentFooterText)
        }
    }

    private var defaultSection: some View {
        Section {
            SecureField("Access code", text: $accessCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button {
                if hasLocalFile {
                    showReplaceConfirmForDownload = true
                } else {
                    Task { await downloadDefault() }
                }
            } label: {
                HStack {
                    Text("Download Default Avionics PDF")
                    Spacer()
                    if isDownloading {
                        ProgressView()
                    }
                }
            }
            .disabled(isDownloading)
        } header: {
            Text("Default Document")
        } footer: {
            Text("Use the shared access code to download the default Avionics PDF.")
        }
    }

    private var rebuildSection: some View {
        Section {
            Button {
                showRebuildConfirm = true
            } label: {
                Text("Rebuild Avionics Guide Index")
            }
        } footer: {
            Text("Clears the cached Avionics guide index and rebuilds it next time the guide is opened.")
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                try DocumentStorage.save(from: url, kind: .g3000)
                hasLocalFile = true
                metaInfo = DocumentStorage.meta(for: .g3000)
                _ = G3000IndexCache.clear()
                statusMessage = "Avionics PDF loaded."
            } catch {
                statusMessage = "Unable to import the Avionics PDF."
            }
        case .failure:
            statusMessage = "Unable to import the Avionics PDF."
        }
        showStatusAlert = true
    }

    @MainActor
    private func downloadDefault() async {
        let trimmed = accessCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Enter the access code first."
            showStatusAlert = true
            return
        }
        isDownloading = true
        defer { isDownloading = false }
        do {
            let data = try await DefaultDocumentService.download(kind: .g3000, accessCode: trimmed)
            try DocumentStorage.save(data: data, kind: .g3000)
            hasLocalFile = true
            metaInfo = DocumentStorage.meta(for: .g3000)
            _ = G3000IndexCache.clear()
            statusMessage = "Default Avionics PDF downloaded."
        } catch {
            statusMessage = error.localizedDescription
        }
        showStatusAlert = true
    }

    private func formattedSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
