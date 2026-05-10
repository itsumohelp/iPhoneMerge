import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let items: [ComparisonHistory]
    var onSelect: (ComparisonHistory) -> Void
    var onDelete: (IndexSet) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock",
                        description: Text("Comparison history will appear here.")
                    )
                } else {
                    List {
                        ForEach(items) { item in
                            Button {
                                guard item.isRestorable else { return }
                                onSelect(item)
                                dismiss()
                            } label: {
                                row(item)
                            }
                            .buttonStyle(.plain)
                            .opacity(item.isRestorable ? 1 : 0.45)
                        }
                        .onDelete(perform: onDelete)
                    }
                }
            }
            .navigationTitle("History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func row(_ item: ComparisonHistory) -> some View {
        HStack(spacing: 10) {
            Image(systemName: typeIcon(item.type))
                .foregroundStyle(typeColor(item.type))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.topLabel)
                    .font(.body)
                    .lineLimit(1)
                if !item.bottomLabel.isEmpty {
                    Text(item.bottomLabel)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(item.date, style: .relative) + Text(" ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if item.isRestorable {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func typeIcon(_ type: HistoryType) -> String {
        switch type {
        case .url:    return "link"
        case .file:   return "doc.fill"
        case .manual: return "pencil"
        }
    }

    private func typeColor(_ type: HistoryType) -> Color {
        switch type {
        case .url:    return .blue
        case .file:   return .orange
        case .manual: return .secondary
        }
    }
}
