import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.12),
                        .clear
                    ],
                    startPoint: .init(x: phase - 0.5, y: 0.5),
                    endPoint: .init(x: phase + 0.5, y: 0.5)
                )
                .blendMode(.sourceAtop)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Primitive

struct SkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.quaternary)
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Dashboard Skeleton
// Matches DashboardView exactly: StatCards, Quick Actions GroupBox, Info GroupBox

struct DashboardSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats — same grid as real dashboard
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    skeletonStatCard(title: "Formulae", icon: "terminal", color: .blue)
                    skeletonStatCard(title: "Casks", icon: "macwindow", color: .purple)
                    skeletonStatCard(title: "Outdated", icon: "arrow.triangle.2.circlepath", color: .orange)
                    skeletonStatCard(title: "Disk Usage", icon: "internaldrive", color: .gray)
                }

                // Quick Actions — real GroupBox label, shimmer button content
                GroupBox("Quick Actions") {
                    HStack(spacing: 12) {
                        skeletonActionButton("Update Homebrew", icon: "arrow.clockwise", color: .blue)
                        skeletonActionButton("Upgrade All", icon: "arrow.up.circle", color: .green)
                        skeletonActionButton("Cleanup", icon: "trash", color: .orange)
                        skeletonActionButton("Run Doctor", icon: "stethoscope", color: .red)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Info — real labels, shimmer values
                GroupBox("Info") {
                    VStack(alignment: .leading, spacing: 8) {
                        skeletonInfoRow("Homebrew Version", valueWidth: 180)
                        skeletonInfoRow("Cache Size", valueWidth: 60)
                        skeletonInfoRow("Total Installed", valueWidth: 90)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func skeletonStatCard(title: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }
            SkeletonBlock(width: 55, height: 28)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func skeletonActionButton(_ title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .frame(width: 100, height: 60)
        .foregroundStyle(color.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
        .shimmer()
    }

    private func skeletonInfoRow(_ label: String, valueWidth: CGFloat) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            SkeletonBlock(width: valueWidth, height: 14)
        }
    }
}

// MARK: - Package List Skeleton
// Matches PackageRow: icon, name+desc, version, status dot+text

struct PackageListSkeleton: View {
    var body: some View {
        List {
            ForEach(0..<12, id: \.self) { _ in
                HStack(spacing: 10) {
                    Image(systemName: "terminal")
                        .font(.system(size: 14))
                        .foregroundStyle(.quaternary)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        SkeletonBlock(width: CGFloat.random(in: 80...160), height: 14)
                        SkeletonBlock(width: CGFloat.random(in: 150...280), height: 10)
                    }

                    Spacer()

                    SkeletonBlock(width: 55, height: 12)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(.quaternary)
                            .frame(width: 7, height: 7)
                        SkeletonBlock(width: 48, height: 11)
                    }
                    .frame(width: 75, alignment: .leading)
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}

// MARK: - Service List Skeleton
// Matches ServicesListView Table: Name, Status dot, User, PID, Actions

struct ServiceListSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { i in
                HStack(spacing: 16) {
                    SkeletonBlock(width: CGFloat.random(in: 100...160), height: 14)
                        .frame(minWidth: 150, alignment: .leading)

                    HStack(spacing: 4) {
                        Circle().fill(.quaternary).frame(width: 8, height: 8)
                        SkeletonBlock(width: 50, height: 12)
                    }
                    .frame(width: 80, alignment: .leading)

                    SkeletonBlock(width: 50, height: 12)
                        .frame(width: 100, alignment: .leading)

                    SkeletonBlock(width: 30, height: 12)
                        .frame(width: 80, alignment: .leading)

                    Spacer()

                    SkeletonBlock(width: 60, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(i.isMultiple(of: 2) ? Color.clear : Color.primary.opacity(0.02))
            }
            Spacer()
        }
    }
}

// MARK: - Detail Skeleton
// Matches PackageDetailView: header with name+type+buttons, divider, info grid, homepage, dependencies

struct DetailSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            SkeletonBlock(width: 160, height: 26)
                            SkeletonBlock(width: 55, height: 20)
                                .clipShape(Capsule())
                        }
                        SkeletonBlock(width: 280, height: 14)
                    }
                    Spacer()
                    SkeletonBlock(width: 75, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Divider()

                // Details grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                    detailRowSkeleton("Installed Version")
                    detailRowSkeleton("Latest Version")
                    detailRowSkeleton("Tap")
                    detailRowSkeleton("Status")
                }

                // Homepage
                GroupBox("Homepage") {
                    SkeletonBlock(width: 250, height: 14)
                }

                // Dependencies
                GroupBox("Dependencies") {
                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonBlock(width: CGFloat.random(in: 50...80), height: 24)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func detailRowSkeleton(_ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            SkeletonBlock(width: 90, height: 14)
        }
    }
}

// MARK: - Generic Skeleton

struct GenericSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(width: 20, height: 20)
                        .shimmer()
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonBlock(width: CGFloat.random(in: 100...200), height: 14)
                        SkeletonBlock(width: CGFloat.random(in: 150...250), height: 10)
                    }
                    Spacer()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
