import SwiftUI
#if os(iOS)
import UIKit
#endif

struct TextInputPanel: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    #if os(iOS)
                    if let str = UIPasteboard.general.string { text = str }
                    #elseif os(macOS)
                    if let str = NSPasteboard.general.string(forType: .string) { text = str }
                    #endif
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Enter or paste text...")
                        .foregroundStyle(.tertiary)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .frame(maxHeight: .infinity)
    }
}
