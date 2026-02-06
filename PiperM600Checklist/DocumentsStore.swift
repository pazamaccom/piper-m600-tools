import Foundation

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case personal
    case aircraft
    case company

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personal:
            return "Personal"
        case .aircraft:
            return "Aircraft"
        case .company:
            return "Company"
        }
    }
}

struct DocumentItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var filename: String
    var category: DocumentCategory
    var order: Int
    var dateAdded: Date
}

@MainActor
final class DocumentsStore: ObservableObject {
    @Published private(set) var documents: [DocumentItem] = []

    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var storageURL: URL {
        documentsDirectory.appendingPathComponent("documents.json")
    }

    private var documentsFolderURL: URL {
        documentsDirectory.appendingPathComponent("UserDocuments", isDirectory: true)
    }

    init() {
        load()
    }

    func documents(in category: DocumentCategory) -> [DocumentItem] {
        documents
            .filter { $0.category == category }
            .sorted { lhs, rhs in
                if lhs.order == rhs.order {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.order < rhs.order
            }
    }

    func load() {
        guard let data = try? Data(contentsOf: storageURL) else {
            documents = []
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([DocumentItem].self, from: data) {
            documents = decoded
        } else {
            documents = []
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(documents) else { return }
        try? data.write(to: storageURL, options: [.atomic])
    }

    func importDocument(from sourceURL: URL, name: String, category: DocumentCategory) throws {
        try ensureDocumentsFolder()

        let needsAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if needsAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let originalName = sourceURL.deletingPathExtension().lastPathComponent
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = trimmedName.isEmpty ? originalName : trimmedName
        let sanitized = sanitizeFilename(displayName)
        let fileExtension = sourceURL.pathExtension.isEmpty ? "pdf" : sourceURL.pathExtension
        let targetURL = uniqueTargetURL(baseName: sanitized, fileExtension: fileExtension)

        try fileManager.copyItem(at: sourceURL, to: targetURL)

        let nextOrder = (documents(in: category).map { $0.order }.max() ?? 0) + 1
        let item = DocumentItem(
            id: UUID(),
            name: displayName,
            filename: targetURL.lastPathComponent,
            category: category,
            order: nextOrder,
            dateAdded: Date()
        )
        documents.append(item)
        save()
    }

    func delete(_ item: DocumentItem) {
        if let index = documents.firstIndex(of: item) {
            documents.remove(at: index)
            let url = documentsFolderURL.appendingPathComponent(item.filename)
            try? fileManager.removeItem(at: url)
            normalizeOrder(for: item.category)
            save()
        }
    }

    func move(from offsets: IndexSet, to destination: Int, category: DocumentCategory) {
        var items = documents(in: category)
        items.move(fromOffsets: offsets, toOffset: destination)
        for (index, item) in items.enumerated() {
            if let originalIndex = documents.firstIndex(of: item) {
                documents[originalIndex].order = index + 1
            }
        }
        save()
    }

    func url(for item: DocumentItem) -> URL {
        documentsFolderURL.appendingPathComponent(item.filename)
    }

    private func ensureDocumentsFolder() throws {
        if !fileManager.fileExists(atPath: documentsFolderURL.path) {
            try fileManager.createDirectory(at: documentsFolderURL, withIntermediateDirectories: true)
        }
    }

    private func normalizeOrder(for category: DocumentCategory) {
        let items = documents(in: category)
        for (index, item) in items.enumerated() {
            if let originalIndex = documents.firstIndex(of: item) {
                documents[originalIndex].order = index + 1
            }
        }
    }

    private func sanitizeFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-_"))
        let cleaned = String(name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" })
        let collapsed = cleaned.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func uniqueTargetURL(baseName: String, fileExtension: String) -> URL {
        let safeBase = baseName.isEmpty ? "Document" : baseName
        var candidate = documentsFolderURL.appendingPathComponent(safeBase).appendingPathExtension(fileExtension)
        var counter = 1
        while fileManager.fileExists(atPath: candidate.path) {
            let name = "\(safeBase)-\(counter)"
            candidate = documentsFolderURL.appendingPathComponent(name).appendingPathExtension(fileExtension)
            counter += 1
        }
        return candidate
    }
}
