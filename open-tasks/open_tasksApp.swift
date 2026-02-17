//
//  open_tasksApp.swift
//  open-tasks
//
//  Created by Tarik Villalobos on 2/16/26.
//

import SwiftUI
import Combine
import AppKit

@main
struct open_tasksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(id: "todo-window") {
            ContentView()
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)

        MenuBarExtra("OpenTasks", systemImage: "checklist") {
            MenuBarContent()
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarContent: View {
    @StateObject private var windowStore = TodoWindowStore.shared
    @Environment(\.openWindow) private var openWindow
    @State private var isTasksExpanded = false
    @State private var expandedWindowIDs: Set<ObjectIdentifier> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                isTasksExpanded.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checklist")
                    Text("Open OpenTasks")
                    Spacer(minLength: 6)
                    Image(systemName: isTasksExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            .handCursorOnHover()

            if isTasksExpanded {
                Divider()

                Button("Open Another") {
                    openWindow(id: "todo-window")
                    NSApp.activate(ignoringOtherApps: true)
                }
                .padding(.vertical, 6)
                .handCursorOnHover()

                Divider()

                if windowStore.items.isEmpty {
                    Text("No lists open")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                } else {
                    ForEach(windowStore.items) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Button {
                                    windowStore.focusWindow(id: item.id)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "rectangle.stack")
                                        Text(item.title)
                                        Spacer(minLength: 0)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                TopbarHoverIcon(symbol: "pencil")

                                TopbarHoverIcon(symbol: "trash")

                                TopbarHoverIcon(
                                    symbol: expandedWindowIDs.contains(item.id) ? "chevron.down" : "chevron.right"
                                ) {
                                    toggleExpandedTasks(for: item.id)
                                }
                            }
                            .padding(.vertical, 4)

                            if expandedWindowIDs.contains(item.id) {
                                let entries = windowStore.taskEntries(for: item.id)
                                if entries.isEmpty {
                                    Text("No tasks yet")
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 24)
                                        .padding(.bottom, 4)
                                } else {
                                    ForEach(entries) { entry in
                                        Button(entry.title) {
                                            windowStore.focusWindow(id: item.id)
                                        }
                                        .lineLimit(1)
                                        .padding(.leading, 24)
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    Button("Close All Open") {
                        windowStore.closeAll()
                    }
                    .disabled(windowStore.items.isEmpty)
                    .padding(.vertical, 6)
                    .handCursorOnHover()
                }
            }

            Divider()

            Button(action: {}) {
                Label("Config", systemImage: "gearshape")
            }
            .padding(.vertical, 8)
            .handCursorOnHover()

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .padding(.vertical, 8)
            .handCursorOnHover()
        }
        .padding(.horizontal, 10)
        .frame(width: 280, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeInOut(duration: 0.15), value: isTasksExpanded)
        .animation(.easeInOut(duration: 0.15), value: expandedWindowIDs)
        .onAppear {
            isTasksExpanded = true
        }
        .onChange(of: windowStore.items.map(\.id)) { currentIDs in
            expandedWindowIDs = expandedWindowIDs.intersection(Set(currentIDs))
        }
    }

    private func toggleExpandedTasks(for windowID: ObjectIdentifier) {
        if expandedWindowIDs.contains(windowID) {
            expandedWindowIDs.remove(windowID)
        } else {
            expandedWindowIDs.insert(windowID)
        }
    }
}

private struct HandCursorOnHoverModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

private extension View {
    func handCursorOnHover() -> some View {
        modifier(HandCursorOnHoverModifier())
    }
}

private struct TopbarHoverIcon: View {
    let symbol: String
    var action: () -> Void = {}

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? .black.opacity(0.12) : .clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isHovered ? .black.opacity(0.30) : .clear, lineWidth: 1)
                        )
                )
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

final class TodoWindowStore: ObservableObject {
    static let shared = TodoWindowStore()

    struct Item: Identifiable {
        let id: ObjectIdentifier
        let title: String
    }

    struct TaskEntry: Identifiable {
        let id = UUID()
        let windowID: ObjectIdentifier
        let windowTitle: String
        let title: String
    }

    @Published private(set) var items: [Item] = []
    @Published private(set) var taskEntries: [TaskEntry] = []

    private final class WeakWindow {
        weak var value: NSWindow?

        init(_ value: NSWindow) {
            self.value = value
        }
    }

    private var windows: [ObjectIdentifier: WeakWindow] = [:]
    private var titles: [ObjectIdentifier: String] = [:]
    private var tasksByWindow: [ObjectIdentifier: [String]] = [:]
    private var closeObservers: [ObjectIdentifier: NSObjectProtocol] = [:]
    private var order: [ObjectIdentifier] = []
    private var nextTitleIndex = 1

    private init() {}

    func register(window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard windows[id] == nil else {
            refreshItems()
            return
        }

        windows[id] = WeakWindow(window)
        titles[id] = "OpenTask \(nextTitleIndex)"
        tasksByWindow[id] = []
        order.append(id)
        nextTitleIndex += 1

        let closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.remove(windowID: id)
        }

        closeObservers[id] = closeObserver
        refreshItems()
    }

    func updateTasks(window: NSWindow, tasks: [String]) {
        let id = ObjectIdentifier(window)
        if windows[id] == nil {
            register(window: window)
        }
        tasksByWindow[id] = tasks
        refreshItems()
    }

    func focusWindow(id: ObjectIdentifier) {
        guard let window = windows[id]?.value else {
            remove(windowID: id)
            return
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeAll() {
        let currentIDs = order
        for id in currentIDs {
            guard let window = windows[id]?.value else {
                remove(windowID: id)
                continue
            }
            unregister(window: window)
            window.orderOut(nil)
            window.close()
        }
        refreshItems()
    }

    func unregister(window: NSWindow) {
        let id = ObjectIdentifier(window)
        remove(windowID: id)
    }

    func taskEntries(for windowID: ObjectIdentifier) -> [TaskEntry] {
        taskEntries.filter { $0.windowID == windowID }
    }

    private func remove(windowID: ObjectIdentifier, shouldRefresh: Bool = true) {
        if let observer = closeObservers[windowID] {
            NotificationCenter.default.removeObserver(observer)
            closeObservers.removeValue(forKey: windowID)
        }
        windows.removeValue(forKey: windowID)
        titles.removeValue(forKey: windowID)
        tasksByWindow.removeValue(forKey: windowID)
        order.removeAll { $0 == windowID }
        if shouldRefresh {
            refreshItems()
        }
    }

    private func refreshItems() {
        var validIDs: [ObjectIdentifier] = []
        var newItems: [Item] = []
        var newTaskEntries: [TaskEntry] = []

        for id in order {
            guard let window = windows[id]?.value else {
                remove(windowID: id, shouldRefresh: false)
                continue
            }
            _ = window
            validIDs.append(id)
            let windowTitle = titles[id] ?? "OpenTask"
            newItems.append(Item(id: id, title: windowTitle))

            let windowTasks = tasksByWindow[id] ?? []
            for taskTitle in windowTasks where !taskTitle.isEmpty {
                newTaskEntries.append(
                    TaskEntry(
                        windowID: id,
                        windowTitle: windowTitle,
                        title: taskTitle
                    )
                )
            }
        }

        order = validIDs
        items = newItems
        taskEntries = newTaskEntries
    }
}
