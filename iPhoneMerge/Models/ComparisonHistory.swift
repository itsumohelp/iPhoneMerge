import Foundation
import Combine
import SwiftUI

enum HistoryType: String, Codable {
    case url, file, manual
}

struct ComparisonHistory: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let type: HistoryType
    let topURL: String?
    let bottomURL: String?
    let topPath: String?
    let bottomPath: String?

    var topLabel: String {
        switch type {
        case .url:    return topURL.flatMap { URL(string: $0)?.lastPathComponent } ?? topURL ?? "-"
        case .file:   return topPath.map { ($0 as NSString).lastPathComponent } ?? "-"
        case .manual: return "Manual input"
        }
    }

    var bottomLabel: String {
        switch type {
        case .url:    return bottomURL.flatMap { URL(string: $0)?.lastPathComponent } ?? bottomURL ?? "-"
        case .file:   return bottomPath.map { ($0 as NSString).lastPathComponent } ?? "-"
        case .manual: return ""
        }
    }

    var isRestorable: Bool { type != .manual }
}

class HistoryManager: ObservableObject {
    @Published private(set) var items: [ComparisonHistory] = []

    private let maxCount = 10
    private let key = "iPhoneMerge.comparisonHistory"

    init() { load() }

    func addURL(topURL: String, bottomURL: String) {
        insert(ComparisonHistory(
            date: .now, type: .url,
            topURL: topURL, bottomURL: bottomURL,
            topPath: nil, bottomPath: nil
        ))
    }

    func addFile(topPath: String, bottomPath: String) {
        insert(ComparisonHistory(
            date: .now, type: .file,
            topURL: nil, bottomURL: nil,
            topPath: topPath, bottomPath: bottomPath
        ))
    }

    func addManual() {
        insert(ComparisonHistory(
            date: .now, type: .manual,
            topURL: nil, bottomURL: nil,
            topPath: nil, bottomPath: nil
        ))
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    private func insert(_ history: ComparisonHistory) {
        items.insert(history, at: 0)
        if items.count > maxCount { items = Array(items.prefix(maxCount)) }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([ComparisonHistory].self, from: data)
        else { return }
        items = decoded
    }
}
