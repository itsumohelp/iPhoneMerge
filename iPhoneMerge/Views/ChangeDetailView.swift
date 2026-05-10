import SwiftUI

struct ChangeDetailView: View {
    let group: ChangeGroup
    let baseIsTop: Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage("changeDetailWrapLines") private var wrapLines: Bool = false

    private var lineNumberWidth: CGFloat {
        let baseMax = (group.baseStartLine ?? 0) + group.baseLines.count
        let otherMax = (group.otherStartLine ?? 0) + group.otherLines.count
        let digits = String(max(baseMax, otherMax, 1)).count
        return CGFloat(max(digits, 3)) * 7.5 + 4
    }

    private var shareText: String {
        var parts: [String] = []
        if !group.baseLines.isEmpty {
            let label = baseIsTop ? "Top (before)" : "Bottom (before)"
            parts.append("--- \(label) ---")
            for (i, line) in group.baseLines.enumerated() {
                parts.append("\((group.baseStartLine ?? 1) + i): \(line)")
            }
        }
        if !group.otherLines.isEmpty {
            if !parts.isEmpty { parts.append("") }
            let label = baseIsTop ? "Bottom (after)" : "Top (after)"
            parts.append("+++ \(label) +++")
            for (i, line) in group.otherLines.enumerated() {
                parts.append("\((group.otherStartLine ?? 1) + i): \(line)")
            }
        }
        return parts.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            ScrollView(wrapLines ? .vertical : [.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    if !group.baseLines.isEmpty {
                        sectionLabel(baseIsTop ? "Top (before)" : "Bottom (before)", color: .red)
                        ForEach(group.baseLines.indices, id: \.self) { i in
                            lineRow(
                                lineNumber: (group.baseStartLine ?? 1) + i,
                                text: group.baseLines[i],
                                color: .red
                            )
                        }
                    }
                    if !group.otherLines.isEmpty {
                        sectionLabel(baseIsTop ? "Bottom (after)" : "Top (after)", color: .green)
                        ForEach(group.otherLines.indices, id: \.self) { i in
                            lineRow(
                                lineNumber: (group.otherStartLine ?? 1) + i,
                                text: group.otherLines[i],
                                color: .green
                            )
                        }
                    }
                }
                .frame(maxWidth: wrapLines ? .infinity : nil, alignment: .leading)
            }
            .navigationTitle("Change Detail")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        wrapLines.toggle()
                    } label: {
                        Label(
                            wrapLines ? "Scroll" : "Wrap",
                            systemImage: wrapLines ? "arrow.left.and.right" : "arrow.turn.down.left"
                        )
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button("Done") { dismiss() }
                }
                #else
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        wrapLines.toggle()
                    } label: {
                        Label(
                            wrapLines ? "Scroll" : "Wrap",
                            systemImage: wrapLines ? "arrow.left.and.right" : "arrow.turn.down.left"
                        )
                    }
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button("Done") { dismiss() }
                }
                #endif
            }
        }
    }

    private func lineRow(lineNumber: Int, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 0) {
            lineNumberLabel(lineNumber)
            textContent(text, color: color)
        }
        .padding(.vertical, 2)
        .background(color.opacity(0.08))
    }

    @ViewBuilder
    private func textContent(_ text: String, color: Color) -> some View {
        let display = text.isEmpty ? " " : text
        if wrapLines {
            Text(display)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 12)
        } else {
            Text(display)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(color)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.trailing, 12)
        }
    }

    private func lineNumberLabel(_ number: Int) -> some View {
        Text("\(number)")
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color.secondary.opacity(0.5))
            .frame(width: lineNumberWidth, alignment: .trailing)
            .padding(.horizontal, 6)
    }

    private func sectionLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .frame(maxWidth: wrapLines ? .infinity : nil, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.05))
    }
}
