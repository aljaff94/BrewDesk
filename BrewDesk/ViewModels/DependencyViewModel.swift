import Foundation

struct DependencyNode: Identifiable, Sendable {
    let id = UUID()
    let name: String
    var children: [DependencyNode]
    let isBuildDependency: Bool
}

@Observable
@MainActor
final class DependencyViewModel {
    var formulae: [Formula] = []
    var selectedFormula: Formula?
    var dependencyTree: [DependencyNode] = []
    var reverseDeps: [String] = []
    var isLoading = true
    var error: BrewError?

    private let client: any BrewClient
    private let cache: BrewCache

    init(client: any BrewClient, cache: BrewCache) {
        self.client = client
        self.cache = cache
    }

    func load(forceRefresh: Bool = false) async {
        let hasCachedData = cache.installedPackages != nil
        if !hasCachedData {
            isLoading = true
        }
        error = nil
        do {
            let info = try await cache.getInstalledPackages(forceRefresh: forceRefresh)
            formulae = info.formulae
        } catch let e as BrewError {
            error = e
        } catch {
            self.error = .decodingFailed(error.localizedDescription)
        }
        isLoading = false
    }

    func buildTree(for formula: Formula) {
        selectedFormula = formula
        dependencyTree = formula.dependencies.map { dep in
            buildNode(name: dep, isBuild: false, visited: [])
        } + formula.buildDependencies.map { dep in
            buildNode(name: dep, isBuild: true, visited: [])
        }

        // Reverse dependencies
        reverseDeps = formulae
            .filter { $0.dependencies.contains(formula.name) || $0.buildDependencies.contains(formula.name) }
            .map(\.name)
    }

    private func buildNode(name: String, isBuild: Bool, visited: Set<String>) -> DependencyNode {
        guard !visited.contains(name) else {
            return DependencyNode(name: "\(name) (circular)", children: [], isBuildDependency: isBuild)
        }

        var newVisited = visited
        newVisited.insert(name)

        let children: [DependencyNode]
        if let formula = formulae.first(where: { $0.name == name }) {
            children = formula.dependencies.map { dep in
                buildNode(name: dep, isBuild: false, visited: newVisited)
            }
        } else {
            children = []
        }

        return DependencyNode(name: name, children: children, isBuildDependency: isBuild)
    }
}
