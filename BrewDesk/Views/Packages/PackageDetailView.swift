import SwiftUI
import AppKit

struct PackageDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PackageDetailViewModel?
    @State private var selectedVersion: String = ""

    let package: Package

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(vm.package.displayName)
                                    .font(.title.bold())
                                Text(vm.package.packageType.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.tertiary, in: Capsule())

                                // Open app button for casks
                                if case .cask = vm.package, vm.package.isInstalled,
                                   let appURL = findCaskApp(vm.package.name) {
                                    Button {
                                        NSWorkspace.shared.open(appURL)
                                    } label: {
                                        Label("Open", systemImage: "arrow.up.forward.app")
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            if let desc = vm.package.description {
                                Text(desc)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        actionButtons(vm)
                    }

                    Divider()

                    // Details grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                        detailRow("Installed Version", value: vm.package.installedVersion ?? "Not installed")
                        detailRow("Latest Version", value: vm.package.latestVersion ?? "Unknown")
                        detailRow("Tap", value: vm.package.tap ?? "N/A")
                        detailRow("Status", value: statusText(vm.package))
                        if let diskUsage = vm.diskUsage {
                            detailRow("Disk Usage", value: diskUsage)
                        }
                        if let installDate = vm.package.installDate {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Installed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(installDate, format: .dateTime.month().day().year())
                                    .fontWeight(.medium)
                                Text(installDate, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Homepage
                    if let homepage = vm.package.homepage, let url = URL(string: homepage) {
                        GroupBox("Homepage") {
                            Link(homepage, destination: url)
                                .font(.callout)
                        }
                    }

                    // Dependencies
                    if case .formula(let formula) = vm.package, !formula.allDependencies.isEmpty {
                        GroupBox("Dependencies") {
                            FlowLayout(spacing: 6) {
                                ForEach(formula.dependencies, id: \.self) { dep in
                                    Text(dep)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.blue.opacity(0.1), in: Capsule())
                                }
                                ForEach(formula.buildDependencies, id: \.self) { dep in
                                    Text("\(dep) (build)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.orange.opacity(0.1), in: Capsule())
                                }
                            }
                        }
                    }

                    // Reverse dependencies
                    if !vm.reverseDeps.isEmpty {
                        GroupBox("Required By (\(vm.reverseDeps.count))") {
                            FlowLayout(spacing: 6) {
                                ForEach(vm.reverseDeps, id: \.self) { dep in
                                    Text(dep)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.purple.opacity(0.1), in: Capsule())
                                }
                            }
                        }
                    }

                    // Caveats
                    if let caveats = vm.package.caveats {
                        GroupBox("Caveats") {
                            Text(caveats)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(24)
            } else {
                DetailSkeleton()
            }
        }
        .task {
            let vm = PackageDetailViewModel(package: package, client: appState.brewClient)
            viewModel = vm
            await vm.loadExtras()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func actionButtons(_ vm: PackageDetailViewModel) -> some View {
        HStack(spacing: 8) {
            if vm.package.isInstalled {
                if vm.package.isOutdated {
                    Button("Upgrade") {
                        Task {
                            await appState.runOperation(
                                title: "Upgrading \(vm.package.name)",
                                stream: vm.upgradeStream()
                            )
                            await vm.refresh()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if case .formula(let formula) = vm.package {
                    Button(formula.pinned ? "Unpin" : "Pin") {
                        Task { try? await vm.togglePin() }
                    }
                    .buttonStyle(.bordered)
                }

                Button("Uninstall", role: .destructive) {
                    Task {
                        await appState.runOperation(
                            title: "Uninstalling \(vm.package.name)",
                            stream: vm.uninstallStream()
                        )
                        await vm.refresh()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                if !versionedFormulae(vm).isEmpty {
                    Picker("Version", selection: $selectedVersion) {
                        Text(vm.package.name).tag("")
                        ForEach(versionedFormulae(vm), id: \.self) { v in
                            Text(v).tag(v)
                        }
                    }
                    .frame(width: 140)
                }

                Button("Install") {
                    Task {
                        let installName = selectedVersion.isEmpty ? vm.package.name : selectedVersion
                        let isCask = vm.package.packageType == .cask
                        await appState.runOperation(
                            title: "Installing \(installName)",
                            stream: appState.brewClient.install(installName, isCask: isCask)
                        )
                        await vm.refresh()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .disabled(appState.isOperationRunning)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func versionedFormulae(_ vm: PackageDetailViewModel) -> [String] {
        if case .formula(let f) = vm.package {
            return f.versionedFormulae
        }
        return []
    }

    private func statusText(_ pkg: Package) -> String {
        if pkg.isOutdated { return "Outdated" }
        if pkg.isInstalled { return "Installed" }
        if pkg.isDeprecated { return "Deprecated" }
        return "Available"
    }

    private func findCaskApp(_ name: String) -> URL? {
        let appName = name
            .split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined()
        let candidates = [
            "/Applications/\(appName).app",
            "/Applications/\(name).app",
        ]
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        let appsDir = URL(fileURLWithPath: "/Applications")
        if let apps = try? FileManager.default.contentsOfDirectory(at: appsDir, includingPropertiesForKeys: nil) {
            return apps.first { url in
                url.pathExtension == "app" &&
                url.deletingPathExtension().lastPathComponent
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "")
                    .contains(name.replacingOccurrences(of: "-", with: ""))
            }
        }
        return nil
    }
}

// Simple flow layout for dependency tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, containerWidth: proposal.width ?? 0)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, containerWidth: bounds.width)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(subviews: Subviews, containerWidth: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
