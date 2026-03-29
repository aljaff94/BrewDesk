import SwiftUI
import UserNotifications

@main
struct BrewDeskApp: App {
    @State private var appState: AppState
    @AppStorage("autoUpdateOnLaunch") private var autoUpdateOnLaunch = false
    @AppStorage("updateCheckInterval") private var updateCheckInterval = 6.0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    init() {
        let client: any BrewClient
        do {
            client = try LiveBrewClient()
        } catch {
            client = MockBrewClient()
        }
        _appState = State(initialValue: AppState(brewClient: client))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 800, minHeight: 500)
                .task {
                    await onLaunch()
                }
                .task(id: updateCheckInterval) {
                    await startPeriodicUpdateCheck()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1000, height: 650)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Operation History") {
                    appState.showOperationHistory = true
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "mug")
                if appState.outdatedCount > 0 {
                    Text("\(appState.outdatedCount)")
                        .font(.caption2)
                }
            }
        }

        Settings {
            SettingsView()
                .environment(appState)
        }
    }

    private func onLaunch() async {
        // Request notification permission
        if notificationsEnabled {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        }

        // Auto-update on launch
        if autoUpdateOnLaunch {
            await appState.runOperation(
                title: "Auto-updating Homebrew",
                stream: appState.brewClient.update()
            )
            // Don't show the sheet for auto-update
            appState.showOperationSheet = false
        }

        await appState.refreshOutdatedCount()
    }

    private func startPeriodicUpdateCheck() async {
        guard updateCheckInterval > 0 else { return }
        let intervalSeconds = updateCheckInterval * 3600

        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(intervalSeconds))
            guard !Task.isCancelled else { return }

            let previousCount = appState.outdatedCount
            await appState.refreshOutdatedCount()

            // Send notification if new outdated packages found
            if notificationsEnabled && appState.outdatedCount > previousCount {
                await sendOutdatedNotification(count: appState.outdatedCount)
            }
        }
    }

    private func sendOutdatedNotification(count: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Homebrew Updates Available"
        content.body = "\(count) package\(count == 1 ? "" : "s") can be upgraded."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "outdated-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
