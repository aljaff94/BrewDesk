import SwiftUI

struct AddTapSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var tapName = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Tap")
                .font(.headline)

            TextField("user/repo (e.g., homebrew/cask-fonts)", text: $tapName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Button("Add") {
                    Task {
                        await appState.runOperation(
                            title: "Adding tap \(tapName)",
                            stream: appState.brewClient.addTap(tapName)
                        )
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(tapName.isEmpty || !tapName.contains("/"))
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
