import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if appState.outdatedCount > 0 {
                Text("\(appState.outdatedCount) outdated package\(appState.outdatedCount == 1 ? "" : "s")")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Button("Upgrade All") {
                    Task {
                        await appState.runOperation(
                            title: "Upgrading All Packages",
                            stream: appState.brewClient.upgrade(nil)
                        )
                        await appState.refreshOutdatedCount()
                    }
                }
                .padding(.horizontal)
                .disabled(appState.isOperationRunning)
            } else {
                Text("All packages up to date")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Divider()

            Button("Update Homebrew") {
                Task {
                    await appState.runOperation(
                        title: "Updating Homebrew",
                        stream: appState.brewClient.update()
                    )
                    await appState.refreshOutdatedCount()
                }
            }
            .padding(.horizontal)
            .disabled(appState.isOperationRunning)

            Button("Check for Updates") {
                Task { await appState.refreshOutdatedCount() }
            }
            .padding(.horizontal)

            Divider()

            Button("Open BrewDesk") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                if let window = NSApplication.shared.windows.first(where: { $0.title == "BrewDesk" || $0.isKeyWindow }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .padding(.horizontal)

            Button("Quit BrewDesk") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: 220)
    }
}
