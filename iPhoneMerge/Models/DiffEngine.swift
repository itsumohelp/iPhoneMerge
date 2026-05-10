import Foundation

enum DiffEngine {
    static func diff(original: String, revised: String) -> DiffResult {
        let a = original.components(separatedBy: "\n")
        let b = revised.components(separatedBy: "\n")
        let m = a.count
        let n = b.count

        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 1...m {
            for j in 1...n {
                dp[i][j] = a[i-1] == b[j-1]
                    ? dp[i-1][j-1] + 1
                    : max(dp[i-1][j], dp[i][j-1])
            }
        }

        var lines: [DiffLine] = []
        var i = m, j = n
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && a[i-1] == b[j-1] {
                lines.append(DiffLine(type: .unchanged, text: a[i-1]))
                i -= 1; j -= 1
            } else if j > 0 && (i == 0 || dp[i][j-1] >= dp[i-1][j]) {
                lines.append(DiffLine(type: .added, text: b[j-1]))
                j -= 1
            } else {
                lines.append(DiffLine(type: .removed, text: a[i-1]))
                i -= 1
            }
        }

        return DiffResult(lines: lines.reversed())
    }
}
