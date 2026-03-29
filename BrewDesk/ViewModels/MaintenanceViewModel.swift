import Foundation

@Observable
@MainActor
final class MaintenanceViewModel {
    var doctorOutput: [String] = []
    var doctorWarnings: [TextOutputParser.DoctorWarning] = []
    var cleanupItems: [TextOutputParser.CleanupItem] = []
    var isRunningDoctor = false
    var isRunningCleanup = false
    var isDoctorDone = false
    var isCleanupDone = false
    var cacheSize = ""

    private let client: any BrewClient

    init(client: any BrewClient) {
        self.client = client
    }

    func runDoctor() async {
        isRunningDoctor = true
        isDoctorDone = false
        doctorOutput = []
        doctorWarnings = []

        do {
            for try await line in client.doctor() {
                doctorOutput.append(line)
            }
        } catch {}

        doctorWarnings = TextOutputParser.parseDoctorOutput(doctorOutput.joined(separator: "\n"))
        isRunningDoctor = false
        isDoctorDone = true
    }

    func runCleanupDryRun() async {
        isRunningCleanup = true
        isCleanupDone = false
        cleanupItems = []
        var output: [String] = []

        do {
            for try await line in client.cleanup(dryRun: true) {
                output.append(line)
            }
        } catch {}

        cleanupItems = TextOutputParser.parseCleanupOutput(output.joined(separator: "\n"))
        isRunningCleanup = false
        isCleanupDone = true
    }

    func cleanupStream() -> AsyncThrowingStream<String, Error> {
        client.cleanup(dryRun: false)
    }

    func loadCacheSize() async {
        cacheSize = await DiskUsageCalculator.cacheSize()
    }
}
