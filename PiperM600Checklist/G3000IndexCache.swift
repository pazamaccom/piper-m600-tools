import Foundation

enum G3000IndexCache {
    static let filename = "g3000_index_v1.json"
    static let didClearNotification = Notification.Name("G3000IndexCacheDidClear")
    private static let clearedFlagKey = "g3000_index_cleared_flag"

    static var url: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return (caches ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent(filename)
    }

    @discardableResult
    static func clear() -> Bool {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            UserDefaults.standard.set(true, forKey: clearedFlagKey)
            NotificationCenter.default.post(name: didClearNotification, object: nil)
            return true
        } catch {
            return false
        }
    }

    static func consumeClearedFlag() -> Bool {
        let flag = UserDefaults.standard.bool(forKey: clearedFlagKey)
        if flag {
            UserDefaults.standard.set(false, forKey: clearedFlagKey)
        }
        return flag
    }
}
