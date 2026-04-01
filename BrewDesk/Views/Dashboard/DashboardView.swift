import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DashboardViewModel?
    @State private var hoveredAction: String?

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: 0) {
                    // MARK: - Health Banner
                    healthBanner(vm)
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                    // MARK: - Stat Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                        statCard(
                            value: "\(vm.formulaeCount)",
                            label: "Formulae",
                            icon: "terminal.fill",
                            accent: Color(nsColor: .systemBlue)
                        )
                        statCard(
                            value: "\(vm.casksCount)",
                            label: "Casks",
                            icon: "macwindow",
                            accent: Color(nsColor: .systemPurple)
                        )
                        statCard(
                            value: vm.diskUsage,
                            label: "Disk Used",
                            icon: "internaldrive.fill",
                            accent: Color(nsColor: .systemGray)
                        )
                        statCard(
                            value: "\(vm.servicesCount)",
                            label: "Active Services",
                            icon: "bolt.fill",
                            accent: Color(nsColor: .systemTeal)
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)

                    // MARK: - Composition Bar
                    compositionBar(vm)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 20)

                    // MARK: - Main Content
                    HStack(alignment: .top, spacing: 16) {
                        // Left Column
                        VStack(spacing: 14) {
                            quickActionsCard(vm)
                            if vm.totalOutdated > 0 {
                                outdatedCard(vm)
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)

                        // Right Column
                        VStack(spacing: 14) {
                            if !vm.recentFormulae.isEmpty || !vm.recentCasks.isEmpty {
                                recentInstallsCard(vm)
                            }
                            if !appState.operationHistory.isEmpty {
                                activityCard()
                            }
                            systemInfoCard(vm)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
                .overlay {
                    if vm.isLoading {
                        DashboardSkeleton()
                            .background(.ultraThinMaterial)
                    }
                }
            } else {
                DashboardSkeleton()
            }
        }
        .navigationTitle("Dashboard")
        .task {
            let vm = DashboardViewModel(client: appState.brewClient, cache: appState.cache)
            viewModel = vm
            await vm.load()
        }
        .refreshable {
            await viewModel?.load(forceRefresh: true)
        }
    }

    // MARK: - Health Banner

    private func healthBanner(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: 20) {
            // Health Ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 6)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: healthScore(vm))
                    .stroke(
                        healthColor(vm).gradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Image(systemName: healthIcon(vm))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(healthColor(vm))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(healthTitle(vm))
                    .font(.system(size: 15, weight: .semibold))
                Text(healthSubtitle(vm))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Package total
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(vm.totalInstalled)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("packages installed")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }

    // MARK: - Stat Card

    private func statCard(value: String, label: String, icon: String, accent: Color) -> some View {
        HStack(spacing: 0) {
            // Accent edge
            RoundedRectangle(cornerRadius: 2)
                .fill(accent.gradient)
                .frame(width: 3)
                .padding(.vertical, 10)

            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(accent)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            .padding(.leading, 10)
            .padding(.vertical, 10)

            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // MARK: - Composition Bar

    private func compositionBar(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Label("Package Composition", systemImage: "chart.bar.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                Spacer()
                HStack(spacing: 12) {
                    legendDot("Formulae", color: Color(nsColor: .systemBlue))
                    legendDot("Casks", color: Color(nsColor: .systemPurple))
                    if vm.totalOutdated > 0 {
                        legendDot("Outdated", color: Color(nsColor: .systemOrange))
                    }
                    if vm.pinnedCount > 0 {
                        legendDot("Pinned", color: Color(nsColor: .systemGreen))
                    }
                }
            }

            GeometryReader { geo in
                let total = max(CGFloat(vm.totalInstalled), 1)
                let formulaeW = (CGFloat(vm.formulaeCount) / total) * geo.size.width
                let casksW = (CGFloat(vm.casksCount) / total) * geo.size.width

                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(nsColor: .systemBlue).gradient)
                        .frame(width: max(formulaeW, 2))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(nsColor: .systemPurple).gradient)
                        .frame(width: max(casksW, 2))
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    private func legendDot(_ text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(.system(size: 10)).foregroundStyle(.tertiary)
        }
    }

    // MARK: - Quick Actions Card

    private func quickActionsCard(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Quick Actions", icon: "bolt.fill")
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                actionRow("Update Homebrew", subtitle: "Fetch latest package info", icon: "arrow.clockwise", color: Color(nsColor: .systemBlue), id: "update") {
                    await appState.runOperation(title: "Updating Homebrew", stream: appState.brewClient.update())
                    appState.cache.invalidateAll()
                    await vm.load(forceRefresh: true)
                }
                thinDivider()
                actionRow("Upgrade All", subtitle: "\(vm.totalOutdated) packages available", icon: "arrow.up.circle.fill", color: Color(nsColor: .systemGreen), id: "upgrade") {
                    await appState.runOperation(title: "Upgrading All Packages", stream: appState.brewClient.upgrade(nil))
                    appState.cache.invalidatePackages()
                    await vm.load(forceRefresh: true)
                }
                thinDivider()
                actionRow("Cleanup", subtitle: "Remove old versions & cache", icon: "xmark.bin.fill", color: Color(nsColor: .systemOrange), id: "cleanup") {
                    await appState.runOperation(title: "Cleaning Up", stream: appState.brewClient.cleanup(dryRun: false))
                    appState.cache.invalidatePackages()
                    await vm.load(forceRefresh: true)
                }
                thinDivider()
                actionRow("Doctor", subtitle: "Diagnose system issues", icon: "stethoscope", color: Color(nsColor: .systemRed), id: "doctor") {
                    await appState.runOperation(title: "Running Doctor", stream: appState.brewClient.doctor())
                }
            }
            .padding(.bottom, 6)
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // MARK: - Outdated Card

    private func outdatedCard(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader("Outdated", icon: "exclamationmark.arrow.circlepath")
                Spacer()
                Text("\(vm.totalOutdated)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .systemOrange), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                let allOutdated = vm.outdatedFormulae.map { ($0.name, $0.installedVersions.first ?? "?", $0.currentVersion, "terminal.fill", Color(nsColor: .systemBlue)) }
                    + vm.outdatedCasks.map { ($0.name, $0.installedVersions.first ?? "?", $0.currentVersion, "macwindow", Color(nsColor: .systemPurple)) }

                ForEach(Array(allOutdated.prefix(8).enumerated()), id: \.offset) { i, item in
                    HStack(spacing: 8) {
                        Image(systemName: item.3)
                            .font(.system(size: 10))
                            .foregroundStyle(item.4)
                            .frame(width: 16)
                        Text(item.0)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                        Text(item.1)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.quaternary)
                        Text(item.2)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color(nsColor: .systemOrange))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    if i < min(allOutdated.count, 8) - 1 {
                        thinDivider()
                    }
                }

                if vm.totalOutdated > 8 {
                    Button {
                        appState.selectedSidebar = .outdated
                    } label: {
                        Text("View all \(vm.totalOutdated) outdated")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(nsColor: .systemBlue))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // MARK: - Recent Installs Card

    private func recentInstallsCard(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Recently Installed", icon: "clock.arrow.circlepath")
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                let items = recentPackages(vm)
                ForEach(Array(items.enumerated()), id: \.element.name) { i, item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(item.color)
                            .frame(width: 16)
                        Text(item.name)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                        Text(item.version)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                        if let date = item.date {
                            Text(date, style: .relative)
                                .font(.system(size: 10))
                                .foregroundStyle(.quaternary)
                                .frame(width: 65, alignment: .trailing)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    if i < items.count - 1 {
                        thinDivider()
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // MARK: - Activity Card

    private func activityCard() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Activity", icon: "list.bullet.clipboard.fill")
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(appState.operationHistory.prefix(4).enumerated()), id: \.element.id) { i, record in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(record.success ? Color(nsColor: .systemGreen) : Color(nsColor: .systemRed))
                            .frame(width: 6, height: 6)
                        Text(record.title)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Spacer()
                        Text(record.timestamp, style: .relative)
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    if i < min(appState.operationHistory.count, 4) - 1 {
                        thinDivider()
                    }
                }

                if appState.operationHistory.count > 4 {
                    Button("View All History") {
                        appState.showOperationHistory = true
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(nsColor: .systemBlue))
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
            }
            .padding(.bottom, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // MARK: - System Info Card

    private func systemInfoCard(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("System", icon: "gearshape.fill")
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                infoRow("Homebrew", value: vm.brewVersion.components(separatedBy: "\n").first ?? vm.brewVersion)
                thinDivider()
                infoRow("Cache", value: vm.cacheUsage)
                thinDivider()
                infoRow("Pinned", value: "\(vm.pinnedCount)")
                if vm.deprecatedCount > 0 {
                    thinDivider()
                    HStack {
                        Text("Deprecated")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(vm.deprecatedCount)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(nsColor: .systemRed))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                }
            }
            .padding(.bottom, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // MARK: - Shared Components

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.4)
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 10))
        }
        .foregroundStyle(.secondary)
    }

    private func thinDivider() -> some View {
        Rectangle()
            .fill(.primary.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 38)
    }

    private func actionRow(_ title: String, subtitle: String, icon: String, color: Color, id: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(hoveredAction == id ? 0.15 : 0.08))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredAction = isHovered ? id : nil
            }
        }
        .disabled(appState.isOperationRunning)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    // MARK: - Health Helpers

    private func healthScore(_ vm: DashboardViewModel) -> Double {
        let total = max(Double(vm.totalInstalled), 1)
        let outdatedRatio = Double(vm.totalOutdated) / total
        let deprecatedRatio = Double(vm.deprecatedCount) / total
        return max(0, min(1, 1.0 - outdatedRatio - deprecatedRatio * 0.5))
    }

    private func healthColor(_ vm: DashboardViewModel) -> Color {
        let score = healthScore(vm)
        if score > 0.9 { return Color(nsColor: .systemGreen) }
        if score > 0.7 { return Color(nsColor: .systemYellow) }
        return Color(nsColor: .systemOrange)
    }

    private func healthIcon(_ vm: DashboardViewModel) -> String {
        let score = healthScore(vm)
        if score > 0.9 { return "checkmark" }
        if score > 0.7 { return "exclamationmark" }
        return "exclamationmark.triangle.fill"
    }

    private func healthTitle(_ vm: DashboardViewModel) -> String {
        let score = healthScore(vm)
        if score > 0.9 { return "System Healthy" }
        if score > 0.7 { return "Updates Available" }
        return "Needs Attention"
    }

    private func healthSubtitle(_ vm: DashboardViewModel) -> String {
        var parts: [String] = []
        if vm.totalOutdated > 0 { parts.append("\(vm.totalOutdated) outdated") }
        if vm.deprecatedCount > 0 { parts.append("\(vm.deprecatedCount) deprecated") }
        if parts.isEmpty { return "All \(vm.totalInstalled) packages are current" }
        return parts.joined(separator: " \u{00B7} ")
    }

    // MARK: - Data Helpers

    private struct RecentItem {
        let name: String
        let version: String
        let icon: String
        let color: Color
        let date: Date?
    }

    private func recentPackages(_ vm: DashboardViewModel) -> [RecentItem] {
        var items: [RecentItem] = []
        for f in vm.recentFormulae {
            items.append(RecentItem(
                name: f.name,
                version: f.installedVersion ?? f.stableVersion ?? "",
                icon: "terminal.fill",
                color: Color(nsColor: .systemBlue),
                date: f.installed.first.map { Date(timeIntervalSince1970: TimeInterval($0.time ?? 0)) }
            ))
        }
        for c in vm.recentCasks {
            items.append(RecentItem(
                name: c.displayName,
                version: c.installedVersion ?? "",
                icon: "macwindow",
                color: Color(nsColor: .systemPurple),
                date: c.installedTime.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            ))
        }
        return items.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }.prefix(6).map { $0 }
    }
}
