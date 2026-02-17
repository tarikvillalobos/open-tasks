//
//  open_tasksApp.swift
//  open-tasks
//
//  Created by Tarik Villalobos on 2/16/26.
//

import SwiftUI

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
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open OpenTasks") {
            openWindow(id: "todo-window")
            NSApp.activate(ignoringOtherApps: true)
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
