import SwiftUI

struct MergeResultView: View {
    let result: DiffResult
    @State private var baseIsTop = true
    @State private var selectedGroup: ChangeGroup?

    private var items: [DiffViewItem] {
        result.viewItems(baseIsTop: baseIsTop)
    }

    private var lineNumberWidth: CGFloat {
        let maxNum = items.compactMap(\.lineNumber).max() ?? 1
        return CGFloat(max(String(maxNum).count, 3)) * 7.5 + 4
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Base", selection: $baseIsTop) {
                Text("Base: Top").tag(true)
                Text("Base: Bottom").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Divider()

            HStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(items) { item in
                            itemRow(item)
                        }
                    }
                }
                .animation(.default, value: baseIsTop)

                overviewBar
            }
            .frame(maxHeight: .infinity)
        }
        .navigationTitle("Diff Result")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: result.shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                ShareLink(item: result.shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            #endif
        }
        .sheet(item: $selectedGroup) { group in
            ChangeDetailView(group: group, baseIsTop: baseIsTop)
        }
    }

    // MARK: - Overview Bar

    private var overviewBar: some View {
        Canvas { context, size in
            let total = max(items.count, 1)
            let segH = size.height / CGFloat(total)

            for (i, item) in items.enumerated() {
                switch item.kind {
                case .unchanged:
                    continue
                case .changed, .insertion:
                    let rect = CGRect(
                        x: 1,
                        y: CGFloat(i) * segH,
                        width: size.width - 2,
                        height: max(segH, 2)
                    )
                    context.fill(Path(rect), with: .color(.red.opacity(0.75)))
                }
            }
        }
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .frame(width: 8)
        .padding(.vertical, 2)
        .padding(.trailing, 2)
    }

    // MARK: - Row

    @ViewBuilder
    private func itemRow(_ item: DiffViewItem) -> some View {
        switch item.kind {
        case .unchanged(let text):
            HStack(alignment: .top, spacing: 0) {
                lineNumberView(item.lineNumber)
                Text(" ").frame(width: 12)
                Text(text.isEmpty ? " " : text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 1)

        case .changed(let text, let group):
            Button { selectedGroup = group } label: {
                HStack(alignment: .top, spacing: 0) {
                    lineNumberView(item.lineNumber)
                    Text("~")
                        .frame(width: 12)
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                    Text(text.isEmpty ? " " : text)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 1)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.orange.opacity(0.12))

        case .insertion(let group):
            Button { selectedGroup = group } label: {
                HStack(spacing: 0) {
                    lineNumberView(nil)
                    Text("+")
                        .frame(width: 12)
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                    Text("\(group.otherLines.count) line(s) inserted")
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .font(.system(.callout, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 1)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.green.opacity(0.12))
        }
    }

    private func lineNumberView(_ number: Int?) -> some View {
        Text(number.map { "\($0)" } ?? "")
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color.secondary.opacity(0.5))
            .frame(width: lineNumberWidth, alignment: .trailing)
            .padding(.trailing, 6)
    }
}
