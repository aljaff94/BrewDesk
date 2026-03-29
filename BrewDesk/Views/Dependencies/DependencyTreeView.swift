import SwiftUI

struct DependencyTreeView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DependencyViewModel?
    @State private var searchText = ""
    @State private var selectedName: String?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    GenericSkeleton()
                } else if let error = vm.error {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    } actions: {
                        Button("Retry") { Task { await vm.load() } }
                    }
                } else {
                    HStack(spacing: 0) {
                        // Left: formula list
                        VStack(spacing: 0) {
                            // Filter field
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("Filter formulae...", text: $searchText)
                                    .textFieldStyle(.plain)
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(8)
                            .background(.bar)

                            Divider()

                            List(filteredFormulae(vm), selection: $selectedName) { formula in
                                Text(formula.name)
                                    .tag(formula.name as String?)
                            }
                            .listStyle(.sidebar)
                            .onChange(of: selectedName) { _, newValue in
                                if let name = newValue,
                                   let formula = vm.formulae.first(where: { $0.name == name }) {
                                    vm.buildTree(for: formula)
                                }
                            }
                        }
                        .frame(width: 220)

                        Divider()

                        // Right: dependency tree
                        if let selected = vm.selectedFormula {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Dependencies of \(selected.name)")
                                        .font(.headline)

                                    if vm.dependencyTree.isEmpty {
                                        Text("No dependencies")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        ForEach(vm.dependencyTree) { node in
                                            DependencyNodeView(node: node)
                                        }
                                    }

                                    if !vm.reverseDeps.isEmpty {
                                        Divider()
                                        Text("Used by (\(vm.reverseDeps.count))")
                                            .font(.headline)
                                        FlowLayout(spacing: 6) {
                                            ForEach(vm.reverseDeps, id: \.self) { dep in
                                                Text(dep)
                                                    .font(.caption)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(.purple.opacity(0.1), in: Capsule())
                                            }
                                        }
                                    }
                                }
                                .padding(20)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            ContentUnavailableView(
                                "Select a Formula",
                                systemImage: "point.3.connected.trianglepath.dotted",
                                description: Text("Choose a formula from the left to view its dependency tree.")
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            } else {
                GenericSkeleton()
            }
        }
        .navigationTitle("Dependencies")
        .task {
            let vm = DependencyViewModel(client: appState.brewClient)
            viewModel = vm
            await vm.load()
        }
    }

    private func filteredFormulae(_ vm: DependencyViewModel) -> [Formula] {
        if searchText.isEmpty { return vm.formulae }
        return vm.formulae.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

struct DependencyNodeView: View {
    let node: DependencyNode
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(node.children) { child in
                DependencyNodeView(node: child)
                    .padding(.leading, 12)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: node.isBuildDependency ? "hammer" : "shippingbox")
                    .font(.caption)
                    .foregroundStyle(node.isBuildDependency ? .orange : .blue)
                Text(node.name)
                    .fontWeight(.medium)
                if node.isBuildDependency {
                    Text("build")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
