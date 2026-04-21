import Foundation
import Combine

final class NotificationStore: ObservableObject {
    static let shared = NotificationStore()

    @Published private(set) var items: [AppNotification] = []

    private var storageKey = "app_notifications"

    private init() {
        load()
    }

    func setOwnerId(_ id: String?) {
        let key = id?.isEmpty == false ? "app_notifications_\(id!)" : "app_notifications_guest"
        if key == storageKey { return }
        storageKey = key
        items = []
        load()
    }

    func add(_ item: AppNotification) {
        items.insert(item, at: 0)
        save()
    }

    func markRead(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        if items[idx].isRead { return }
        items[idx].isRead = true
        save()
    }

    func markAllRead() {
        var changed = false
        for idx in items.indices {
            if !items[idx].isRead {
                items[idx].isRead = true
                changed = true
            }
        }
        if changed { save() }
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) else {
            return
        }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let diff = Int(now.timeIntervalSince(date))
        if diff < 60 { return "Just now" }
        let minutes = diff / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    static func absoluteTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
