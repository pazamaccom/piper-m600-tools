import Foundation

enum StoredDocumentKind: String {
    case poh
    case g3000

    var displayName: String {
        switch self {
        case .poh:
            return "POH"
        case .g3000:
            return "G3000"
        }
    }

    var localFileName: String {
        switch self {
        case .poh:
            return "POH.pdf"
        case .g3000:
            return "G3000.pdf"
        }
    }
}

enum DocumentStorage {
    private enum MetaKey {
        static func size(_ kind: StoredDocumentKind) -> String {
            "doc_meta_size_\(kind.rawValue)"
        }

        static func date(_ kind: StoredDocumentKind) -> String {
            "doc_meta_date_\(kind.rawValue)"
        }
    }

    static func localURL(for kind: StoredDocumentKind) -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent(kind.localFileName)
    }

    static func exists(_ kind: StoredDocumentKind) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: kind).path)
    }

    static func save(data: Data, kind: StoredDocumentKind) throws {
        let url = localURL(for: kind)
        try data.write(to: url, options: [.atomic])
        storeMeta(kind: kind, size: data.count, date: Date())
    }

    static func save(from fileURL: URL, kind: StoredDocumentKind) throws {
        let destination = localURL(for: kind)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: fileURL, to: destination)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: destination.path) {
            let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
            let date = (attributes[.modificationDate] as? Date) ?? Date()
            storeMeta(kind: kind, size: size, date: date)
        } else {
            storeMeta(kind: kind, size: 0, date: Date())
        }
    }

    @discardableResult
    static func delete(_ kind: StoredDocumentKind) -> Bool {
        let url = localURL(for: kind)
        guard FileManager.default.fileExists(atPath: url.path) else { return true }
        do {
            try FileManager.default.removeItem(at: url)
            clearMeta(kind: kind)
            return true
        } catch {
            return false
        }
    }

    static func meta(for kind: StoredDocumentKind) -> (size: Int, date: Date)? {
        let defaults = UserDefaults.standard
        let size = defaults.integer(forKey: MetaKey.size(kind))
        guard let date = defaults.object(forKey: MetaKey.date(kind)) as? Date else {
            return nil
        }
        return (size, date)
    }

    private static func storeMeta(kind: StoredDocumentKind, size: Int, date: Date) {
        let defaults = UserDefaults.standard
        defaults.set(size, forKey: MetaKey.size(kind))
        defaults.set(date, forKey: MetaKey.date(kind))
    }

    private static func clearMeta(kind: StoredDocumentKind) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: MetaKey.size(kind))
        defaults.removeObject(forKey: MetaKey.date(kind))
    }
}
