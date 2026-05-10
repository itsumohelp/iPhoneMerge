import SwiftUI

struct URLInputView: View {
    @Environment(\.dismiss) private var dismiss
    var onLoad: (String, String, String, String) -> Void

    @State private var topURLString = ""
    @State private var bottomURLString = ""
    @State private var isFetching = false
    @State private var errorMessage: String?

    private var canFetch: Bool {
        !topURLString.trimmingCharacters(in: .whitespaces).isEmpty &&
        !bottomURLString.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isFetching
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://raw.githubusercontent.com/...", text: $topURLString)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Top URL")
                }

                Section {
                    TextField("https://raw.githubusercontent.com/...", text: $bottomURLString)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Bottom URL")
                } footer: {
                    Text("GitHub: use raw.githubusercontent.com URLs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let message = errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await fetchBoth() }
                    } label: {
                        HStack {
                            Spacer()
                            if isFetching {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Fetching...")
                            } else {
                                Text("Fetch & Compare")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canFetch)
                }
            }
            .navigationTitle("Fetch from URL")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func fetchBoth() async {
        errorMessage = nil
        isFetching = true
        defer { isFetching = false }

        guard
            let topURL = URL(string: topURLString.trimmingCharacters(in: .whitespaces)),
            topURL.scheme == "https" || topURL.scheme == "http"
        else {
            errorMessage = "Top URL is invalid."
            return
        }
        guard
            let bottomURL = URL(string: bottomURLString.trimmingCharacters(in: .whitespaces)),
            bottomURL.scheme == "https" || bottomURL.scheme == "http"
        else {
            errorMessage = "Bottom URL is invalid."
            return
        }

        do {
            async let topFetch = fetchText(from: topURL)
            async let bottomFetch = fetchText(from: bottomURL)
            let (topText, bottomText) = try await (topFetch, bottomFetch)
            onLoad(topText, bottomText, topURLString.trimmingCharacters(in: .whitespaces), bottomURLString.trimmingCharacters(in: .whitespaces))
            dismiss()
        } catch let fetchError as FetchError {
            errorMessage = fetchError.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchText(from url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw FetchError.httpError(url: url, status: http.statusCode)
        }
        guard let text = String(data: data, encoding: .utf8)
                      ?? String(data: data, encoding: .isoLatin1) else {
            throw FetchError.notText(url: url)
        }
        return text
    }
}

private enum FetchError: Error {
    case httpError(url: URL, status: Int)
    case notText(url: URL)

    var message: String {
        switch self {
        case .httpError(let url, let status):
            return "HTTP \(status): \(url.lastPathComponent)"
        case .notText(let url):
            return "Not a text file: \(url.lastPathComponent)"
        }
    }
}
