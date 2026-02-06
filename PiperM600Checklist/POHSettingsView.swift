import SwiftUI
import UniformTypeIdentifiers

struct POHSettingsView: View {
    @AppStorage("default_docs_access_code") private var accessCode = ""
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
    @State private var hasLocalFile = DocumentStorage.exists(.poh)
    @State private var metaInfo = DocumentStorage.meta(for: .poh)

    var body: some View {
        List {
            Section {
                Button("Load POH PDF") {
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
                    Text("Remove Local POH PDF")
                        .foregroundColor(hasLocalFile ? .red : .secondary)
                }
                .disabled(!hasLocalFile || isDownloading)
            } header: {
                Text("Document")
            } footer: {
                if hasLocalFile, let metaInfo {
                    Text("Installed (\(formattedSize(metaInfo.size))), updated \(formattedDate(metaInfo.date)).")
                } else if hasLocalFile {
                    Text("Local POH PDF is installed.")
                } else {
                    Text("No POH PDF loaded.")
                }
            }

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
                        Text("Download Default POH")
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
                Text("Use the shared access code to download the default POH document.")
            }

            Section {
                Button {
                    showRebuildConfirm = true
                } label: {
                    Text("Rebuild POH Search Index")
                }
            } footer: {
                Text("Clears the cached POH index and rebuilds it next time POH is opened.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("POH Settings")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pdf]) { result in
            handleImport(result)
        }
        .alert("Rebuild POH Index?", isPresented: $showRebuildConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Rebuild", role: .destructive) {
                let success = POHIndexCache.clear()
                rebuildMessage = success
                    ? "POH index cleared. It will rebuild next time you open POH."
                    : "Could not clear the POH index. Please try again."
                showRebuildResult = true
            }
        } message: {
            Text("This clears the cached POH index and forces a rebuild.")
        }
        .alert("POH Index", isPresented: $showRebuildResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(rebuildMessage)
        }
        .alert("POH Document", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
        .alert("Remove POH PDF?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if DocumentStorage.delete(.poh) {
                    hasLocalFile = false
                    metaInfo = nil
                    _ = POHIndexCache.clear()
                    statusMessage = "POH PDF removed."
                } else {
                    statusMessage = "Could not remove the POH PDF."
                }
                showStatusAlert = true
            }
        } message: {
            Text("This removes the locally stored POH PDF.")
        }
        .alert("Replace POH PDF?", isPresented: $showReplaceConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Replace", role: .destructive) {
                showImporter = true
            }
        } message: {
            Text("This will replace the current POH PDF.")
        }
        .alert("Replace POH PDF?", isPresented: $showReplaceConfirmForDownload) {
            Button("Cancel", role: .cancel) {}
            Button("Replace", role: .destructive) {
                Task { await downloadDefault() }
            }
        } message: {
            Text("This will replace the current POH PDF with the default document.")
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
                try DocumentStorage.save(from: url, kind: .poh)
                hasLocalFile = true
                metaInfo = DocumentStorage.meta(for: .poh)
                _ = POHIndexCache.clear()
                statusMessage = "POH PDF loaded."
            } catch {
                statusMessage = "Unable to import the POH PDF."
            }
        case .failure:
            statusMessage = "Unable to import the POH PDF."
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
            let data = try await DefaultDocumentService.download(kind: .poh, accessCode: trimmed)
            try DocumentStorage.save(data: data, kind: .poh)
            hasLocalFile = true
            metaInfo = DocumentStorage.meta(for: .poh)
            _ = POHIndexCache.clear()
            statusMessage = "Default POH downloaded."
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
