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
    }
}

private struct MenuBarContent: View {
    @StateObject private var windowStore = TodoWindowStore.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Menu("Open OpenTasks") {
            Button("Open Another") {
                openWindow(id: "todo-window")
                NSApp.activate(ignoringOtherApps: true)
            }

            if windowStore.items.isEmpty {
                Text("No OpenTasks")
            } else {
                Divider()

                ForEach(windowStore.items) { item in
                    Button(item.title) {
                        windowStore.focusWindow(id: item.id)
                    }
                }

                Divider()

                Button("Close All Open") {
                    windowStore.closeAll()
                }
            }
        }

        Button(action: {}) {
            Label("Config", systemImage: "gearshape")
        }

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
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

    @Published private(set) var items: [Item] = []

    private final class WeakWindow {
        weak var value: NSWindow?

        init(_ value: NSWindow) {
            self.value = value
        }
    }

    private var windows: [ObjectIdentifier: WeakWindow] = [:]
    private var titles: [ObjectIdentifier: String] = [:]
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
        order.removeAll { $0 == windowID }
        refreshItems()
    }

    private func refreshItems() {
        var validIDs: [ObjectIdentifier] = []
        var newItems: [Item] = []

        for id in order {
            guard let window = windows[id]?.value else {
                remove(windowID: id)
                continue
            }
            _ = window
            validIDs.append(id)
            newItems.append(Item(id: id, title: titles[id] ?? "OpenTask"))
        }

        order = validIDs
        items = newItems
    }
}
