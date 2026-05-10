import Combine
import SwiftUI

class MergeViewModel: ObservableObject {
    @Published var originalText = ""
    @Published var revisedText = ""
    @Published var diffResult: DiffResult?
    @Published var showResult = false

    var canMerge: Bool {
        !originalText.isEmpty || !revisedText.isEmpty
    }

    func computeDiff() {
        diffResult = DiffEngine.diff(original: originalText, revised: revisedText)
        showResult = true
    }
}
