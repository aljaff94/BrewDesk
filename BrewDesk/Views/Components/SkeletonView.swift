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
// Matches DashboardView exactly: Health Banner, 4 Stat Cards, Composition Bar, Two-Column Cards

struct DashboardSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Health Banner
                skeletonHealthBanner
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                // Stat Cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
                    ForEach(0..<4, id: \.self) { _ in
                        skeletonStatCard
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

                // Composition Bar
                skeletonCompositionBar
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)

                // Two-Column Layout
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 14) {
                        skeletonListCard(header: "Quick Actions", rows: 4, hasSubtitle: true)
                        skeletonListCard(header: "Outdated", rows: 5, hasSubtitle: false, hasBadge: true)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)

                    VStack(spacing: 14) {
                        skeletonListCard(header: "Recently Installed", rows: 5, hasSubtitle: false)
                        skeletonListCard(header: "Activity", rows: 3, hasSubtitle: false)
                        skeletonListCard(header: "System", rows: 3, hasSubtitle: false)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Health Banner Skeleton
    private var skeletonHealthBanner: some View {
        HStack(spacing: 20) {
            // Health Ring placeholder
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 6)
                .frame(width: 52, height: 52)
                .overlay(
                    SkeletonBlock(width: 16, height: 16)
                        .clipShape(Circle())
                )
                .shimmer()

            VStack(alignment: .leading, spacing: 6) {
                SkeletonBlock(width: 120, height: 14)
                SkeletonBlock(width: 180, height: 10)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                SkeletonBlock(width: 50, height: 26)
                SkeletonBlock(width: 100, height: 10)
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }

    // Stat Card Skeleton
    private var skeletonStatCard: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.quaternary)
                .frame(width: 3)
                .padding(.vertical, 10)
                .shimmer()

            VStack(alignment: .leading, spacing: 6) {
                SkeletonBlock(width: 12, height: 12)
                SkeletonBlock(width: 45, height: 18)
                SkeletonBlock(width: 60, height: 8)
            }
            .padding(.leading, 10)
            .padding(.vertical, 10)

            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // Composition Bar Skeleton
    private var skeletonCompositionBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SkeletonBlock(width: 140, height: 10)
                Spacer()
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle().fill(.quaternary).frame(width: 6, height: 6)
                        SkeletonBlock(width: 40, height: 8)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(.quaternary).frame(width: 6, height: 6)
                        SkeletonBlock(width: 30, height: 8)
                    }
                }
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(height: 8)
                .shimmer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // List Card Skeleton
    private func skeletonListCard(header: String, rows: Int, hasSubtitle: Bool, hasBadge: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    SkeletonBlock(width: 10, height: 10)
                    SkeletonBlock(width: CGFloat(header.count * 7), height: 10)
                }
                Spacer()
                if hasBadge {
                    SkeletonBlock(width: 22, height: 16)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { i in
                    HStack(spacing: 8) {
                        if hasSubtitle {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.quaternary)
                                .frame(width: 28, height: 28)
                                .shimmer()
                        } else {
                            SkeletonBlock(width: 10, height: 10)
                                .frame(width: 16)
                        }

                        VStack(alignment: .leading, spacing: hasSubtitle ? 3 : 0) {
                            SkeletonBlock(width: CGFloat.random(in: 70...130), height: 12)
                            if hasSubtitle {
                                SkeletonBlock(width: CGFloat.random(in: 100...170), height: 9)
                            }
                        }
                        Spacer()
                        SkeletonBlock(width: CGFloat.random(in: 35...60), height: 10)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, hasSubtitle ? 6 : 4)

                    if i < rows - 1 {
                        Rectangle()
                            .fill(.primary.opacity(0.04))
                            .frame(height: 0.5)
                            .padding(.leading, 38)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
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
