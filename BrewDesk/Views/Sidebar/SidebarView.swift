import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            ForEach(SidebarSection.allCases, id: \.self) { section in
                Section(section.rawValue) {
                    ForEach(section.items) { item in
                        HStack {
                            Label(item.label, systemImage: item.systemImage)
                            Spacer()
                            if badgeCount(for: item) > 0 {
                                Text("\(badgeCount(for: item))")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(.red)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.globalSearchText = ""
                            appState.selectedSidebar = item
                        }
                        .listRowBackground(
                            appState.selectedSidebar == item
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("BrewDesk")
        .task {
            await appState.refreshOutdatedCount()
        }
    }

    private func badgeCount(for item: SidebarItem) -> Int {
        switch item {
        case .outdated: return appState.outdatedCount
        default: return 0
        }
    }
}
