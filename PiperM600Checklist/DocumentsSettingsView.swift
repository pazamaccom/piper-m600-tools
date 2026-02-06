import SwiftUI
import UniformTypeIdentifiers

struct DocumentsSettingsView: View {
    @ObservedObject var store: DocumentsStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showPicker = false
    @State private var pendingCategory: DocumentCategory?
    @State private var pendingURL: URL?
    @State private var pendingName = ""
    @State private var showNamePrompt = false
    @State private var errorMessage: String?

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            List {
                sectionHeader("Add Documents")
                addButtonRow(title: "Add Personal Document", category: .personal)
                addButtonRow(title: "Add Aircraft Document", category: .aircraft)
                addButtonRow(title: "Add Company Document", category: .company)

                sectionHeader("Personal")
                documentList(for: .personal)

                sectionHeader("Aircraft")
                documentList(for: .aircraft)

                sectionHeader("Company")
                documentList(for: .company)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .foregroundColor(AppTheme.accent)
            }
        }
        .sheet(isPresented: $showPicker) {
            DocumentPicker { url in
                pendingURL = url
                pendingName = url.deletingPathExtension().lastPathComponent
                showNamePrompt = true
            } onCancel: {
                pendingCategory = nil
                pendingURL = nil
            }
        }
        .alert("Document name", isPresented: $showNamePrompt) {
            TextField("Name", text: $pendingName)
            Button("Cancel", role: .cancel) {
                pendingCategory = nil
                pendingURL = nil
            }
            Button("Save") {
                importPending()
            }
        } message: {
            Text("Edit the display name if desired.")
        }
        .alert("Unable to Import", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func documentList(for category: DocumentCategory) -> some View {
        let items = store.documents(in: category)
        if items.isEmpty {
            Text("No documents yet.")
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                .foregroundColor(AppTheme.muted)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        } else {
            ForEach(items) { item in
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: isPadLayout ? 16 : 14, weight: .semibold))
                        .foregroundColor(AppTheme.accent)

                    Text(item.name)
                        .font(.custom("Avenir Next Regular", size: isPadLayout ? 14 : 12))
                        .foregroundColor(AppTheme.text)

                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(cardBackground)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                offsets.map { items[$0] }.forEach(store.delete)
            }
            .onMove { offsets, destination in
                store.move(from: offsets, to: destination, category: category)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom("Avenir Next Condensed Demi Bold", size: isPadLayout ? 18 : 15))
            .foregroundColor(AppTheme.text)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    private func addButtonRow(title: String, category: DocumentCategory) -> some View {
        Button {
            startImport(for: category)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: isPadLayout ? 16 : 14, weight: .semibold))
                    .foregroundColor(AppTheme.accent)

                Text(title)
                    .font(.custom("Avenir Next Regular", size: isPadLayout ? 14 : 12))
                    .foregroundColor(AppTheme.text)

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [AppTheme.card, AppTheme.cardHighlight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.bezelDark, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .inset(by: 1)
                    .stroke(AppTheme.bezelLight, lineWidth: 1)
            )
    }

    private func startImport(for category: DocumentCategory) {
        pendingCategory = category
        showPicker = true
    }

    private func importPending() {
        guard let url = pendingURL, let category = pendingCategory else { return }
        do {
            try store.importDocument(from: url, name: pendingName, category: category)
            pendingCategory = nil
            pendingURL = nil
            pendingName = ""
        } catch {
            errorMessage = "Unable to import the selected document."
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL) -> Void
        private let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
