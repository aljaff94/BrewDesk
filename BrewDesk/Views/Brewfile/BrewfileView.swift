import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BrewfileView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: BrewfileViewModel?
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            if let vm = viewModel {
                // Toolbar
                HStack(spacing: 12) {
                    Button("Export Current Setup") {
                        Task { await vm.exportBrewfile() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isLoading)

                    Menu("Save As...") {
                        Button("Brewfile") { saveBrewfile(vm.brewfileContent, filename: "Brewfile") }
                        Button("JSON") { saveAsJSON() }
                        Button("Plain Text") { saveAsText() }
                    }
                    .disabled(vm.brewfileContent.isEmpty)

                    Button("Import Brewfile") {
                        importBrewfile()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    if !vm.entries.isEmpty {
                        let taps = vm.entries.filter { $0.type == .tap }.count
                        let brews = vm.entries.filter { $0.type == .brew }.count
                        let casks = vm.entries.filter { $0.type == .cask }.count
                        Text("\(taps) taps, \(brews) formulae, \(casks) casks")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .padding()
                .background(.bar)

                if vm.isLoading {
                    ProgressView("Generating Brewfile...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.brewfileContent.isEmpty {
                    // Drop target / empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No Brewfile")
                            .font(.title2.weight(.medium))
                        Text("Click \"Export Current Setup\" to generate a Brewfile,\nor drag & drop a Brewfile here to install from it.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay {
                        if isDropTargeted {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .padding(20)
                        }
                    }
                } else {
                    ScrollView {
                        Text(vm.brewfileContent)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                }
            } else {
                GenericSkeleton()
            }
        }
        .navigationTitle("Brewfile")
        .onDrop(of: [.fileURL, .plainText], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .task {
            viewModel = BrewfileViewModel(client: appState.brewClient)
        }
    }

    // MARK: - Drop

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                    guard let data = data as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    Task { @MainActor in
                        await appState.runOperation(
                            title: "Installing from Brewfile",
                            stream: appState.brewClient.brewfileInstall(from: url.path)
                        )
                    }
                }
                return true
            }
        }
        return false
    }

    // MARK: - Save / Import

    private func saveBrewfile(_ content: String, filename: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = filename
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func saveAsJSON() {
        guard let vm = viewModel else { return }
        let formulae = vm.entries.filter { $0.type == .brew }.map(\.name)
        let casks = vm.entries.filter { $0.type == .cask }.map(\.name)
        let taps = vm.entries.filter { $0.type == .tap }.map(\.name)
        let dict: [String: [String]] = ["taps": taps, "formulae": formulae, "casks": casks]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "packages.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            try? json.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func saveAsText() {
        guard let vm = viewModel else { return }
        let lines = vm.entries.map { "\($0.type.rawValue)\t\($0.name)" }
        let text = lines.joined(separator: "\n")

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "packages.txt"
        panel.allowedContentTypes = [.plainText]
        if panel.runModal() == .OK, let url = panel.url {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func importBrewfile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await appState.runOperation(
                    title: "Installing from Brewfile",
                    stream: appState.brewClient.brewfileInstall(from: url.path)
                )
            }
        }
    }
}
