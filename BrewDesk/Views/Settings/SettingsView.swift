import SwiftUI

struct SettingsView: View {
    @AppStorage("brewPath") private var brewPath = "/opt/homebrew/bin/brew"
    @AppStorage("updateCheckInterval") private var updateCheckInterval = 6.0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoUpdateOnLaunch") private var autoUpdateOnLaunch = false

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            notificationsTab
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            advancedTab
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
        }
        .frame(width: 450, height: 300)
    }

    private var generalTab: some View {
        Form {
            Section("Homebrew") {
                HStack {
                    TextField("Brew Path", text: $brewPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Detect") {
                        if let path = BrewPathResolver.resolve() {
                            brewPath = path
                        }
                    }
                }
            }

            Section("Updates") {
                Toggle("Auto-update on launch", isOn: $autoUpdateOnLaunch)

                HStack {
                    Text("Check for updates every")
                    Picker("", selection: $updateCheckInterval) {
                        Text("1 hour").tag(1.0)
                        Text("3 hours").tag(3.0)
                        Text("6 hours").tag(6.0)
                        Text("12 hours").tag(12.0)
                        Text("24 hours").tag(24.0)
                        Text("Never").tag(0.0)
                    }
                    .frame(width: 120)
                }
            }
        }
        .padding()
    }

    private var notificationsTab: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable notifications", isOn: $notificationsEnabled)
                Text("Get notified when packages have available updates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var advancedTab: some View {
        Form {
            Section("Info") {
                LabeledContent("Brew Path") {
                    Text(brewPath)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent("Cellar") {
                    Text("/opt/homebrew/Cellar")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                LabeledContent("Caskroom") {
                    Text("/opt/homebrew/Caskroom")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .padding()
    }
}
