//
//  RepositoryView.swift
//  open-tasks
//

import AppKit
import ObjectiveC.runtime
import SwiftUI

// MARK: - Data Model

private struct RepoItem: Identifiable {
    let id = UUID()
    let name: String
    let issues: Int
    let prs: Int
    let stars: Int
    let branch: String
    let updatedAgo: String
    let isPinned: Bool
    let isWork: Bool
    let releases: Int
    let ciRuns: Int
    let discussions: Int
    let tags: Int
    let branches: Int
    let contributors: Int
}

// MARK: - Main View

struct RepositoryView: View {
    private let repoListWidth: CGFloat  = 340
    private let detailPanelWidth: CGFloat = 374
    private let panelHorizontalInset: CGFloat = 2
    private let panelVerticalInset: CGFloat = 6
    private let windowEdgePaddingX: CGFloat = 10
    private let windowEdgePaddingY: CGFloat = 12

    @State private var hostWindow: NSWindow?
    @State private var selectedRepo: RepoItem?
    @State private var selectedFilter: RepoFilter = .all
    @EnvironmentObject private var themeStore: AppThemeStore
    @Environment(\.colorScheme) private var systemColorScheme

    private enum RepoFilter: String, CaseIterable, Identifiable {
        case all = "All"; case pinned = "Pinned"; case work = "Work"
        var id: String { rawValue }
    }

    private let repos: [RepoItem] = [
        RepoItem(name: "tarikvillalobos/postme",    issues: 2,  prs: 1, stars: 124,  branch: "main",      updatedAgo: "1 min. ago",  isPinned: true,  isWork: false, releases: 12, ciRuns: 1232, discussions: 0, tags: 13, branches: 1, contributors: 3),
        RepoItem(name: "tarikvillalobos/rentify",   issues: 4,  prs: 5, stars: 892,  branch: "main",      updatedAgo: "14 min. ago", isPinned: true,  isWork: true,  releases: 8,  ciRuns: 421,  discussions: 2, tags: 8,  branches: 3, contributors: 5),
        RepoItem(name: "tarikvillalobos/time-zones",issues: 1,  prs: 0, stars: 340,  branch: "dev",       updatedAgo: "13 min. ago", isPinned: false, isWork: false, releases: 5,  ciRuns: 87,   discussions: 1, tags: 5,  branches: 2, contributors: 2),
        RepoItem(name: "tarikvillalobos/squaddy",   issues: 0,  prs: 2, stars: 56,   branch: "master",    updatedAgo: "1 hr. ago",   isPinned: false, isWork: true,  releases: 3,  ciRuns: 34,   discussions: 0, tags: 3,  branches: 1, contributors: 2),
        RepoItem(name: "tarikvillalobos/api-kit",   issues: 3,  prs: 1, stars: 1205, branch: "feature/v2",updatedAgo: "30 min. ago", isPinned: true,  isWork: true,  releases: 22, ciRuns: 3401, discussions: 5, tags: 22, branches: 4, contributors: 8),
        RepoItem(name: "tarikvillalobos/mnemonic",  issues: 0,  prs: 0, stars: 78,   branch: "main",      updatedAgo: "2 hr. ago",   isPinned: false, isWork: false, releases: 2,  ciRuns: 12,   discussions: 0, tags: 2,  branches: 1, contributors: 1),
        RepoItem(name: "tarikvillalobos/open-tasks",issues: 5,  prs: 3, stars: 412,  branch: "main",      updatedAgo: "4 min. ago",  isPinned: true,  isWork: true,  releases: 16, ciRuns: 892,  discussions: 3, tags: 16, branches: 2, contributors: 4),
    ]

    private var filteredRepos: [RepoItem] {
        switch selectedFilter {
        case .all:    return repos
        case .pinned: return repos.filter { $0.isPinned }
        case .work:   return repos.filter { $0.isWork }
        }
    }

    // MARK: - Theme

    private var isDarkTheme: Bool { themeStore.resolvedColorScheme(systemColorScheme: systemColorScheme) == .dark }
    private var panelFill: Color   { isDarkTheme ? Color(red: 0.12, green: 0.13, blue: 0.16) : Color(red: 0.97, green: 0.97, blue: 0.98) }
    private var panelStroke: Color { isDarkTheme ? .white.opacity(0.14) : .black.opacity(0.08) }
    private var cardFill: Color    { isDarkTheme ? Color(red: 0.16, green: 0.17, blue: 0.20) : .white }
    private var cardStroke: Color  { isDarkTheme ? .white.opacity(0.10) : .black.opacity(0.08) }
    private var prim: Color        { isDarkTheme ? .white.opacity(0.90) : .black.opacity(0.82) }
    private var sec: Color         { isDarkTheme ? .white.opacity(0.55) : .black.opacity(0.48) }
    private var div: Color         { isDarkTheme ? .white.opacity(0.10) : .black.opacity(0.07) }
    private var accent: Color      { Color(red: 0.39, green: 0.44, blue: 0.99) }

    // MARK: - Dimensions

    private var isExpanded: Bool { selectedRepo != nil }

    private var panelWidth: CGFloat {
        isExpanded ? repoListWidth + 1 + detailPanelWidth : repoListWidth
    }

    private var repoListHeight: CGFloat {
        CGFloat(min(filteredRepos.count, 5)) * 72
    }

    private var collapsedHeight: CGFloat {
        56 + 14 + 158 + 14 + 44 + 10 + repoListHeight + 46 + 40 + panelVerticalInset * 2
    }

    private var panelHeight: CGFloat {
        isExpanded ? max(collapsedHeight, 660) : collapsedHeight
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(panelFill)
                .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(panelStroke, lineWidth: 1))
                .padding(.horizontal, panelHorizontalInset)
                .padding(.vertical, panelVerticalInset)

            HStack(alignment: .top, spacing: 0) {
                leftColumn
                if let repo = selectedRepo {
                    Rectangle().fill(div).frame(width: 1).padding(.vertical, 20)
                    RepoDetailPanel(
                        repo: repo, isDarkTheme: isDarkTheme,
                        prim: prim, sec: sec, accent: accent,
                        div: div, cardFill: cardFill, cardStroke: cardStroke
                    )
                    .frame(width: detailPanelWidth)
                    .padding(.horizontal, 18).padding(.top, 20).padding(.bottom, 14)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, panelHorizontalInset)
            .padding(.vertical, panelVerticalInset)
            .overlay(alignment: .top) {
                RepoWindowDragRegion().frame(maxWidth: .infinity).frame(height: 12)
            }
        }
        .frame(width: panelWidth, height: panelHeight)
        .animation(.spring(response: 0.30, dampingFraction: 0.84), value: isExpanded)
        .padding(.horizontal, windowEdgePaddingX)
        .padding(.vertical, windowEdgePaddingY)
        .background(
            RepoWindowConfigurator(targetSize: CGSize(
                width:  panelWidth  + windowEdgePaddingX * 2,
                height: panelHeight + windowEdgePaddingY * 2)
            ) { window in if hostWindow !== window { hostWindow = window } }
        )
    }

    // MARK: - Left column

    private var leftColumn: some View {
        VStack(spacing: 0) {
            header.padding(.bottom, 14)
            heatmapSection.padding(.bottom, 14)
            filterTabs.padding(.bottom, 10)
            repoListSection
            Spacer(minLength: 0)
            footerBar
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .frame(width: repoListWidth - panelHorizontalInset * 2)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 0) {
                Text("Contributions")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(prim).frame(height: 36, alignment: .center)
                Spacer()
            }
            .frame(height: 36).background(RepoWindowDragRegion())

            Button(action: { hostWindow?.close() }) {
                RepoHeaderIcon(symbol: "xmark", isDarkTheme: isDarkTheme)
            }
            .buttonStyle(.plain).repoCursorOnHover()
        }
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("last 12 months")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(sec)
                Spacer()
            }
            ContributionHeatmap(isDarkTheme: isDarkTheme)
                .frame(maxWidth: .infinity).frame(height: 100)
            HStack {
                Text("Nov 2024").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(sec)
                Spacer()
                Text("Dec 2025").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(sec)
            }.padding(.top, 2)
        }
        .padding(.horizontal, 4).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardFill)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(cardStroke, lineWidth: 1)))
    }

    // MARK: - Filter tabs

    private var filterTabs: some View {
        HStack(spacing: 6) {
            ForEach(RepoFilter.allCases) { f in filterTab(f) }
        }
        .padding(.horizontal, 4).padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(cardFill)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(cardStroke, lineWidth: 1)))
    }

    private func filterTab(_ f: RepoFilter) -> some View {
        let isActive = selectedFilter == f
        return Button { withAnimation(.easeInOut(duration: 0.16)) { selectedFilter = f } } label: {
            Text(f.rawValue)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isActive ? prim : sec)
                .frame(maxWidth: .infinity).padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isActive ? accent.opacity(isDarkTheme ? 0.28 : 0.14) : .clear)
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isActive ? accent.opacity(0.40) : .clear, lineWidth: 1))
                )
        }
        .buttonStyle(.plain).repoCursorOnHover()
    }

    // MARK: - Repo list

    private var repoListSection: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(filteredRepos) { repo in
                    RepoRow(
                        repo: repo,
                        isSelected: selectedRepo?.id == repo.id,
                        isDarkTheme: isDarkTheme,
                        primaryColor: prim, secondaryColor: sec,
                        accentColor: accent, dividerColor: div
                    ) {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                            selectedRepo = selectedRepo?.id == repo.id ? nil : repo
                        }
                    }
                }
            }
        }
        .frame(height: repoListHeight)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardFill)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(cardStroke, lineWidth: 1)))
    }

    // MARK: - Footer

    private var footerBar: some View {
        VStack(spacing: 10) {
            Rectangle().fill(div).frame(height: 1)
            HStack {
                Text("\(filteredRepos.count) repositórios")
                Spacer()
                Text("GitHub")
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(sec)
        }
    }
}

// MARK: - Repo Detail Panel

private struct RepoDetailPanel: View {
    let repo: RepoItem
    var isDarkTheme: Bool
    var prim: Color; var sec: Color; var accent: Color
    var div: Color; var cardFill: Color; var cardStroke: Color

    private var subtleFill: Color {
        isDarkTheme ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }
    private var subtleStroke: Color {
        isDarkTheme ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                githubHeader
                dividerLine
                quickActions
                dividerLine
                branchSection
                dividerLine
                menuItems
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // "Open X in GitHub >"
    private var githubHeader: some View {
        Button {
            if let url = URL(string: "https://github.com/\(repo.name.components(separatedBy: "/").last ?? "")") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)
                Text("Open \(repo.name) in GitHub")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(prim)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(sec)
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .repoCursorOnHover()
    }

    // Quick actions: Finder, Terminal, TARS
    private var quickActions: some View {
        VStack(spacing: 0) {
            quickAction(icon: "folder", label: "Open in Finder",   isAccent: false)
            quickAction(icon: "terminal", label: "Open in Terminal", isAccent: false)
            quickAction(icon: "wand.and.stars", label: "Open TARS Agent", isAccent: true)
        }
        .padding(.vertical, 4)
    }

    private func quickAction(icon: String, label: String, isAccent: Bool) -> some View {
        Button {
            // action placeholder
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isAccent ? accent : sec)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isAccent ? accent : prim)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
        .repoCursorOnHover()
    }

    // Branch info + action buttons
    private var branchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Branch name + status
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(prim)
                Text(repo.branch)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(prim)
                Text("Up to date")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(sec)
                Spacer()
            }

            Text("Upstream origin/\(repo.branch) • Fetched \(repo.updatedAgo)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(sec)

            // Sync / Rebase / Reset
            HStack(spacing: 8) {
                branchActionBtn(icon: "arrow.clockwise", label: "Sync")
                branchActionBtn(icon: "arrow.triangle.merge", label: "Rebase")
                branchActionBtn(icon: "arrow.uturn.backward", label: "Reset")
            }

            // Switch Worktree
            Button {} label: {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(sec)
                    Text("Switch Worktree")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(prim)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(sec)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .repoCursorOnHover()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 2)
    }

    private func branchActionBtn(icon: String, label: String) -> some View {
        Button {} label: {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                Text(label).font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(prim)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(subtleFill)
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(subtleStroke, lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .repoCursorOnHover()
    }

    // Menu items list
    private var menuItems: some View {
        VStack(spacing: 0) {
            menuRow(icon: "exclamationmark.circle", label: "Issues",        count: repo.issues)
            menuRow(icon: "arrow.triangle.pull",   label: "Pull Requests",  count: repo.prs)
            menuRow(icon: "shippingbox",           label: "Releases",       count: repo.releases)
            menuRow(icon: "bolt",                  label: "CI Runs",        count: repo.ciRuns)
            menuRow(icon: "bubble.left",           label: "Discussions",    count: repo.discussions > 0 ? repo.discussions : nil)
            menuRow(icon: "tag",                   label: "Tags",           count: repo.tags)
            menuRow(icon: "arrow.triangle.branch", label: "Branches",       count: repo.branches)
            menuRow(icon: "person.2",              label: "Contributors",   count: repo.contributors)
            menuRow(icon: "clock.arrow.circlepath",label: "Open Commits",   count: nil)
        }
        .padding(.vertical, 6)
    }

    private func menuRow(icon: String, label: String, count: Int?) -> some View {
        Button {} label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(sec)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(prim)
                Spacer()
                if let c = count, c > 0 {
                    Text("\(c)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(sec)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(isDarkTheme ? Color.white.opacity(0.10) : Color.black.opacity(0.07)))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 2)
        }
        .buttonStyle(.plain)
        .repoCursorOnHover()
    }

    private var dividerLine: some View {
        Rectangle().fill(div).frame(height: 1).padding(.horizontal, 2)
    }
}

// MARK: - Contribution Heatmap

private struct ContributionHeatmap: View {
    var isDarkTheme: Bool
    private let weeks = 53
    private let days  = 7

    private func intensity(week: Int, day: Int) -> Double {
        let seed = (week * 7 + day + 17) % 13
        let base: [Double] = [0, 0, 0, 0.25, 0.5, 0.75, 1.0, 0.5, 0.25, 0, 0, 0.75, 0.5]
        var v = base[seed]
        if day >= 5 { v *= 0.5 }
        if week % 6 == 2  { v = min(1.0, v + 0.4) }
        if week % 11 == 5 { v = min(1.0, v + 0.6) }
        return v
    }

    private func cellColor(intensity v: Double) -> Color {
        guard v > 0 else {
            return isDarkTheme ? Color(red: 0.20, green: 0.21, blue: 0.26) : Color(red: 0.91, green: 0.91, blue: 0.93)
        }
        return Color(red: 0.39 + v * 0.08, green: 0.25 - v * 0.05, blue: 0.95 - v * 0.12)
            .opacity(0.55 + v * 0.45)
    }

    var body: some View {
        GeometryReader { geo in
            let cW = geo.size.width / CGFloat(weeks)
            let cH = geo.size.height / CGFloat(days)
            let gap: CGFloat = 2
            Canvas { ctx, _ in
                for w in 0..<weeks {
                    for d in 0..<days {
                        let v = intensity(week: w, day: d)
                        let rect = CGRect(x: CGFloat(w)*cW + gap/2, y: CGFloat(d)*cH + gap/2,
                                          width: cW - gap, height: cH - gap)
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(cellColor(intensity: v)))
                    }
                }
            }
        }
    }
}

// MARK: - Repo Row

private struct RepoRow: View {
    let repo: RepoItem
    var isSelected: Bool
    var isDarkTheme: Bool
    var primaryColor: Color
    var secondaryColor: Color
    var accentColor: Color
    var dividerColor: Color
    var onTap: () -> Void

    @State private var isHovered = false

    private var rowBg: Color {
        if isSelected {
            return isDarkTheme ? accentColor.opacity(0.16) : accentColor.opacity(0.08)
        }
        return isHovered
            ? (isDarkTheme ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
            : .clear
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Circle().fill(accentColor).frame(width: 8, height: 8).padding(.top, 5)

                VStack(alignment: .leading, spacing: 4) {
                    Text(repo.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryColor).lineLimit(1)

                    HStack(spacing: 8) {
                        statLabel(icon: "exclamationmark.circle", value: "\(repo.issues) Issues")
                        statLabel(icon: "arrow.triangle.pull",    value: "\(repo.prs) PRs")
                        statLabel(icon: "star",                   value: "\(fmtStars(repo.stars)) Stars")
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 9, weight: .semibold)).foregroundStyle(secondaryColor)
                        Text(repo.branch)
                            .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(secondaryColor)
                        Spacer()
                        Text(repo.updatedAgo)
                            .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(secondaryColor)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(rowBg)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            Rectangle().fill(dividerColor).frame(height: 1).padding(.horizontal, 12)
        }
        .onHover { hovering in
            isHovered = hovering
            hovering ? NSCursor.pointingHand.push() : NSCursor.pop()
        }
    }

    private func statLabel(icon: String, value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            Text(value).font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(secondaryColor)
    }

    private func fmtStars(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000.0) : "\(n)"
    }
}

// MARK: - Header Icon

private struct RepoHeaderIcon: View {
    let symbol: String
    var isDarkTheme: Bool = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(isDarkTheme ? Color.white.opacity(0.62) : Color.black.opacity(0.56))
            .frame(width: 36, height: 36)
            .background(Circle()
                .fill(isDarkTheme ? Color(red: 0.20, green: 0.21, blue: 0.25) : .white)
                .overlay(Circle().stroke(isDarkTheme ? Color.white.opacity(0.14) : Color.black.opacity(0.10), lineWidth: 1)))
    }
}

// MARK: - Cursor modifier

private struct RepoCursorOnHover: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { h in h ? NSCursor.pointingHand.push() : NSCursor.pop() }
    }
}

private extension View {
    func repoCursorOnHover() -> some View { modifier(RepoCursorOnHover()) }
}

// MARK: - Window infrastructure

private struct RepoWindowDragRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { RepoDragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class RepoDragView: NSView {
        override func resetCursorRects() { super.resetCursorRects(); discardCursorRects(); addCursorRect(bounds, cursor: .openHand) }
        override func mouseDown(with event: NSEvent) { NSCursor.closedHand.push(); defer { NSCursor.pop() }; window?.performDrag(with: event) }
    }
}

private struct RepoWindowConfigurator: NSViewRepresentable {
    let targetSize: CGSize
    let onResolve: (NSWindow) -> Void
    private static var patchedClasses: Set<ObjectIdentifier> = []

    init(targetSize: CGSize, onResolve: @escaping (NSWindow) -> Void) {
        self.targetSize = targetSize
        self.onResolve  = onResolve
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let w = view.window else { return }
            configure(w); onResolve(w)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let w = nsView.window else { return }
            let sz = NSSize(width: targetSize.width, height: targetSize.height)
            if w.frame.size != sz { w.setContentSize(sz) }
        }
    }

    private func configure(_ window: NSWindow) {
        window.styleMask      = [.borderless, .fullSizeContentView]
        window.isOpaque       = false
        window.backgroundColor = .clear
        window.hasShadow      = true
        window.level          = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.standardWindowButton(.closeButton)?.isHidden      = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden        = true
        window.setContentSize(NSSize(width: targetSize.width, height: targetSize.height))
        window.center()
        ensureKeyable(window)
    }

    private func ensureKeyable(_ window: NSWindow) {
        guard let cls = object_getClass(window) else { return }
        let clsID = ObjectIdentifier(cls)
        guard !Self.patchedClasses.contains(clsID) else { return }
        let t: @convention(block) (AnyObject) -> Bool = { _ in true }
        class_addMethod(cls, #selector(getter: NSWindow.canBecomeKey),  imp_implementationWithBlock(t), "B@:")
        class_addMethod(cls, #selector(getter: NSWindow.canBecomeMain), imp_implementationWithBlock(t), "B@:")
        RepoWindowConfigurator.patchedClasses.insert(clsID)
    }
}
