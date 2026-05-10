//
//  ContentView.swift
//  iPhoneMerge
//
//  Created by kusakari on 2026/05/10.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = MergeViewModel()
    @StateObject private var historyManager = HistoryManager()
    @State private var showFilePicker = false
    @State private var showURLInput = false
    @State private var showHistory = false
    @State private var fileErrorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextInputPanel(label: "Top", text: $viewModel.originalText)
                Divider()
                TextInputPanel(label: "Bottom", text: $viewModel.revisedText)

                Button(action: {
                    historyManager.addManual()
                    viewModel.computeDiff()
                }) {
                    Text("Merge")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.canMerge ? Color.accentColor : Color.secondary.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.canMerge)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("iPhoneMerge")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Label("History", systemImage: "clock")
                    }
                    Button {
                        showURLInput = true
                    } label: {
                        Label("Fetch from URL", systemImage: "link")
                    }
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Pick 2 Files", systemImage: "doc.on.doc")
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.showResult) {
                if let result = viewModel.diffResult {
                    MergeResultView(result: result)
                }
            }
        }
        .sheet(isPresented: $showURLInput) {
            URLInputView { top, bottom, topURL, bottomURL in
                viewModel.originalText = top
                viewModel.revisedText = bottom
                historyManager.addURL(topURL: topURL, bottomURL: bottomURL)
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(items: historyManager.items, onSelect: { item in
                restoreHistory(item)
            }, onDelete: { offsets in
                historyManager.delete(at: offsets)
            })
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.text, .plainText, .utf8PlainText, .data],
            allowsMultipleSelection: true
        ) { result in
            handleFilePicker(result: result)
        }
        .alert("File Selection Error", isPresented: .constant(fileErrorMessage != nil)) {
            Button("OK") { fileErrorMessage = nil }
        } message: {
            Text(fileErrorMessage ?? "")
        }
    }

    private func handleFilePicker(result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            fileErrorMessage = error.localizedDescription

        case .success(let urls):
            guard urls.count == 2 else {
                fileErrorMessage = urls.count < 2
                    ? "Please select exactly 2 files. You selected \(urls.count) file."
                    : "Please select exactly 2 files. You selected \(urls.count) files."
                return
            }
            loadFiles(urls[0], urls[1])
        }
    }

    private func loadFiles(_ topURL: URL, _ bottomURL: URL) {
        do {
            let top = try readSecureFile(topURL)
            let bottom = try readSecureFile(bottomURL)
            viewModel.originalText = top
            viewModel.revisedText = bottom
            historyManager.addFile(topPath: topURL.path, bottomPath: bottomURL.path)
        } catch {
            fileErrorMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }

    private func restoreHistory(_ item: ComparisonHistory) {
        switch item.type {
        case .url:
            guard let topURLStr = item.topURL, let bottomURLStr = item.bottomURL,
                  let topURL = URL(string: topURLStr), let bottomURL = URL(string: bottomURLStr) else { return }
            Task {
                do {
                    async let topFetch = fetchText(from: topURL)
                    async let bottomFetch = fetchText(from: bottomURL)
                    let (top, bottom) = try await (topFetch, bottomFetch)
                    viewModel.originalText = top
                    viewModel.revisedText = bottom
                } catch {
                    fileErrorMessage = "Failed to restore: \(error.localizedDescription)"
                }
            }
        case .file:
            guard let topPath = item.topPath, let bottomPath = item.bottomPath else { return }
            do {
                viewModel.originalText = try String(contentsOfFile: topPath, encoding: .utf8)
                viewModel.revisedText = try String(contentsOfFile: bottomPath, encoding: .utf8)
            } catch {
                fileErrorMessage = "Failed to restore file: \(error.localizedDescription)"
            }
        case .manual:
            break
        }
    }

    private func fetchText(from url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        guard let text = String(data: data, encoding: .utf8)
                      ?? String(data: data, encoding: .isoLatin1) else {
            throw URLError(.cannotDecodeContentData)
        }
        return text
    }

    private func readSecureFile(_ url: URL) throws -> String {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        return try String(contentsOf: url, encoding: .utf8)
    }
}

#Preview {
    ContentView()
}
