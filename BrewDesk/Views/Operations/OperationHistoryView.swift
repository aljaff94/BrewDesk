import SwiftUI

struct OperationHistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecord: OperationRecord?

    var body: some View {
        NavigationStack {
            Group {
                if appState.operationHistory.isEmpty {
                    ContentUnavailableView {
                        Label("No History", systemImage: "clock")
                    } description: {
                        Text("Operations you run will appear here.")
                    }
                } else {
                    List(appState.operationHistory, selection: Binding(
                        get: { selectedRecord?.id },
                        set: { id in selectedRecord = appState.operationHistory.first { $0.id == id } }
                    )) { record in
                        HStack(spacing: 10) {
                            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(record.success ? .green : .red)
                                .font(.system(size: 14))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.title)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Text(record.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(record.timestamp, format: .dateTime.hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .tag(record.id)
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            }
            .navigationTitle("Operation History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if !appState.operationHistory.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            appState.operationHistory.removeAll()
                        }
                    }
                }
            }
            .sheet(item: $selectedRecord) { record in
                OperationRecordDetailView(record: record)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct OperationRecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: OperationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(record.success ? .green : .red)
                Text(record.title)
                    .font(.headline)
                Spacer()
                Text(record.timestamp, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(record.output.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .background(.black.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 300)
    }
}

extension OperationRecord: Hashable {
    static func == (lhs: OperationRecord, rhs: OperationRecord) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
