import Foundation

final class ChecklistStore: ObservableObject {
    @Published var sections: [ChecklistSection] = []

    private let storageKey = "ChecklistSections.v1"

    init() {
        load()
    }

    func resetToDefault() {
        sections = ChecklistData.defaultSections
        save()
    }

    func resetProgress() {
        sections = sections.map { section in
            var updatedSection = section
            updatedSection.items = section.items.map { item in
                var updatedItem = item
                updatedItem.isChecked = false
                return updatedItem
            }
            return updatedSection
        }
        save()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(sections)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // If saving fails, keep current in-memory state.
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            sections = ChecklistData.defaultSections
            return
        }
        do {
            sections = try JSONDecoder().decode([ChecklistSection].self, from: data)
        } catch {
            sections = ChecklistData.defaultSections
        }
    }
}
