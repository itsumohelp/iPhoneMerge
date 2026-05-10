import Foundation

enum DiffLineType {
    case unchanged, added, removed
}

struct DiffLine: Identifiable {
    let id = UUID()
    let type: DiffLineType
    let text: String
}

struct ChangeGroup: Identifiable {
    let id = UUID()
    let baseLines: [String]
    let otherLines: [String]
    let baseStartLine: Int?
    let otherStartLine: Int?
}

struct DiffViewItem: Identifiable {
    let id = UUID()
    let lineNumber: Int?
    let kind: Kind

    enum Kind {
        case unchanged(String)
        case changed(text: String, group: ChangeGroup)
        case insertion(group: ChangeGroup)
    }
}

struct DiffResult {
    let lines: [DiffLine]

    var addedCount: Int     { lines.filter { $0.type == .added }.count }
    var removedCount: Int   { lines.filter { $0.type == .removed }.count }
    var unchangedCount: Int { lines.filter { $0.type == .unchanged }.count }

    var shareText: String {
        lines.map { line in
            let prefix: String
            switch line.type {
            case .unchanged: prefix = " "
            case .added:     prefix = "+"
            case .removed:   prefix = "-"
            }
            return "\(prefix) \(line.text)"
        }.joined(separator: "\n")
    }

    func viewItems(baseIsTop: Bool) -> [DiffViewItem] {
        var items: [DiffViewItem] = []
        var baseLineNum = 1
        var otherLineNum = 1
        var i = 0

        while i < lines.count {
            let line = lines[i]
            if line.type == .unchanged {
                items.append(DiffViewItem(lineNumber: baseLineNum, kind: .unchanged(line.text)))
                baseLineNum += 1
                otherLineNum += 1
                i += 1
            } else {
                var baseLines: [String] = []
                var otherLines: [String] = []
                let blockBaseStart = baseLineNum
                let blockOtherStart = otherLineNum

                while i < lines.count && lines[i].type != .unchanged {
                    let l = lines[i]
                    let isBase = baseIsTop ? l.type == .removed : l.type == .added
                    if isBase {
                        baseLines.append(l.text)
                        baseLineNum += 1
                    } else {
                        otherLines.append(l.text)
                        otherLineNum += 1
                    }
                    i += 1
                }

                let group = ChangeGroup(
                    baseLines: baseLines,
                    otherLines: otherLines,
                    baseStartLine: baseLines.isEmpty ? nil : blockBaseStart,
                    otherStartLine: otherLines.isEmpty ? nil : blockOtherStart
                )

                if baseLines.isEmpty {
                    items.append(DiffViewItem(lineNumber: nil, kind: .insertion(group: group)))
                } else {
                    for (idx, text) in baseLines.enumerated() {
                        items.append(DiffViewItem(lineNumber: blockBaseStart + idx, kind: .changed(text: text, group: group)))
                    }
                }
            }
        }
        return items
    }
}
