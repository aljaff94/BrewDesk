import SwiftUI

struct OperationSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(appState.operationTitle)
                    .font(.headline)
                Spacer()
                if appState.isOperationRunning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            OperationLogView(lines: appState.operationOutput)
                .frame(minHeight: 300)

            HStack {
                if appState.isOperationRunning {
                    Button("Cancel") {
                        appState.cancelOperation()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Spacer()

                Button(appState.isOperationRunning ? "Running..." : "Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.isOperationRunning)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 600, minHeight: 400)
    }
}
