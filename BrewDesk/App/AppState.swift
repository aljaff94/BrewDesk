import SwiftUI

struct OperationRecord: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let timestamp: Date
    let output: [String]
    let success: Bool
}

@Observable
@MainActor
final class AppState {
    var selectedSidebar: SidebarItem? = .dashboard
    var globalSearchText = ""
    var isOperationRunning = false
    var operationOutput: [String] = []
    var showOperationSheet = false
    var showOperationHistory = false
    var operationTitle = ""
    var operationHistory: [OperationRecord] = []
    var outdatedCount = 0
    var error: BrewError?
    var showError = false

    private var operationTask: Task<Void, Never>?

    let brewClient: any BrewClient

    init(brewClient: any BrewClient) {
        self.brewClient = brewClient
    }

    func runOperation(title: String, stream: AsyncThrowingStream<String, Error>) async {
        operationTitle = title
        operationOutput = []
        isOperationRunning = true
        showOperationSheet = true

        var success = true
        let task = Task {
            do {
                for try await line in stream {
                    guard !Task.isCancelled else { break }
                    operationOutput.append(line)
                }
            } catch is CancellationError {
                operationOutput.append("Operation cancelled.")
                success = false
            } catch let error as BrewError {
                self.error = error
                operationOutput.append("Error: \(error.localizedDescription)")
                success = false
            } catch {
                if !Task.isCancelled {
                    operationOutput.append("Error: \(error.localizedDescription)")
                    success = false
                } else {
                    operationOutput.append("Operation cancelled.")
                    success = false
                }
            }
        }
        operationTask = task
        await task.value

        isOperationRunning = false
        operationTask = nil

        let record = OperationRecord(
            title: title,
            timestamp: Date(),
            output: operationOutput,
            success: success
        )
        operationHistory.insert(record, at: 0)
        if operationHistory.count > 100 {
            operationHistory = Array(operationHistory.prefix(100))
        }
    }

    func cancelOperation() {
        operationTask?.cancel()
    }

    func refreshOutdatedCount() async {
        do {
            let outdated = try await brewClient.outdatedPackages()
            outdatedCount = outdated.formulae.count + outdated.casks.count
        } catch {}
    }
}
