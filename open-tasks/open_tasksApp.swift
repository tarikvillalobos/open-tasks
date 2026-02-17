//
//  open_tasksApp.swift
//  open-tasks
//
//  Created by Tarik Villalobos on 2/16/26.
//

import SwiftUI
import Combine

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

            if isTasksExpanded {
                Divider()

                Button("Open Another") {
                    openWindow(id: "todo-window")
                    NSApp.activate(ignoringOtherApps: true)
                }
                .padding(.vertical, 6)

                Divider()

                if windowStore.items.isEmpty {
                    Text("No lists open")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                } else {
                    ForEach(windowStore.items) { item in
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
                        .lineLimit(1)
                        .padding(.vertical, 4)
                    }

                    Divider()

                    if windowStore.taskEntries.isEmpty {
                        Text("No tasks yet")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(windowStore.taskEntries) { entry in
                            Button(entry.title) {
                                windowStore.focusWindow(id: entry.windowID)
                            }
                            .lineLimit(1)
                            .padding(.vertical, 4)
                        }
                    }
                }

                Divider()

                Button("Close All Open") {
                    windowStore.closeAll()
                }
                .disabled(windowStore.items.isEmpty)
                .padding(.vertical, 6)
            }

            Divider()

            Button(action: {}) {
                Label("Config", systemImage: "gearshape")
            }
            .padding(.vertical, 8)

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 10)
        .frame(width: 280, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.easeInOut(duration: 0.15), value: isTasksExpanded)
        .onAppear {
            isTasksExpanded = true
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
            window.orderOut(nil)
            window.close()
        }
        refreshItems()
    }

    private func remove(windowID: ObjectIdentifier) {
        if let observer = closeObservers[windowID] {
            NotificationCenter.default.removeObserver(observer)
            closeObservers.removeValue(forKey: windowID)
        }
        windows.removeValue(forKey: windowID)
        titles.removeValue(forKey: windowID)
        tasksByWindow.removeValue(forKey: windowID)
        order.removeAll { $0 == windowID }
        refreshItems()
    }

    private func refreshItems() {
        var validIDs: [ObjectIdentifier] = []
        var newItems: [Item] = []
        var newTaskEntries: [TaskEntry] = []

        for id in order {
            guard let window = windows[id]?.value else {
                remove(windowID: id)
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
