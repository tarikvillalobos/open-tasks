//
//  ContentView.swift
//  open-tasks
//
//  Created by Tarik Villalobos on 2/16/26.
//

import AppKit
import ObjectiveC.runtime
import SwiftUI

private struct TodoItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var completed = false
}

struct ContentView: View {
    private let panelWidth: CGFloat = 410
    private let panelHorizontalInset: CGFloat = 2
    private let panelVerticalInset: CGFloat = 6
    private let windowEdgePaddingX: CGFloat = 10
    private let windowEdgePaddingY: CGFloat = 12
    private let maxVisibleTasks = 6
    private let taskRowHeight: CGFloat = 44
    private let expandedTaskRowHeight: CGFloat = 84
    private let taskRowSpacing: CGFloat = 10
    private let emptyStateHeight: CGFloat = 120
    private let staticLayoutHeight: CGFloat = 244

    @State private var newTask = ""
    @State private var tasks: [TodoItem] = []
    @State private var hostWindow: NSWindow?
    @State private var pendingUndo: UndoSnapshot?
    @State private var undoDismissWorkItem: DispatchWorkItem?
    @State private var editingTaskID: UUID?
    @State private var editingTaskTitle = ""
    @State private var expandedTaskIDs: Set<UUID> = []
    @StateObject private var windowStore = TodoWindowStore.shared
    @FocusState private var isInputFocused: Bool
    @Environment(\.openWindow) private var openWindow

    private struct UndoSnapshot {
        let task: TodoItem
        let originalIndex: Int
    }

    private var pendingCount: Int {
        tasks.filter { !$0.completed }.count
    }

    private var completionPercent: Int {
        guard !tasks.isEmpty else { return 0 }
        let done = tasks.filter { $0.completed }.count
        return Int((Double(done) / Double(tasks.count)) * 100)
    }

    private var visibleTaskCount: Int {
        min(tasks.count, maxVisibleTasks)
    }

    private var hostWindowID: ObjectIdentifier? {
        hostWindow.map { ObjectIdentifier($0) }
    }

    private var panelTitle: String {
        guard let windowID = hostWindowID else { return "OpenTasks" }
        guard let item = windowStore.items.first(where: { $0.id == windowID }) else { return "OpenTasks" }
        return item.title.hasPrefix("OpenTask ") ? "OpenTasks" : item.title
    }

    private var tasksContainerHeight: CGFloat {
        guard !tasks.isEmpty else { return emptyStateHeight }
        let visibleTasks = Array(tasks.prefix(visibleTaskCount))
        let rowsHeight = visibleTasks.reduce(CGFloat.zero) { partialResult, task in
            partialResult + rowHeight(for: task)
        }
        let visibleCount = visibleTasks.count
        let spacesHeight = CGFloat(max(visibleCount - 1, 0)) * taskRowSpacing
        return rowsHeight + spacesHeight + 4
    }

    private var panelHeight: CGFloat {
        staticLayoutHeight + tasksContainerHeight
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.13, blue: 0.15).opacity(0.46))
                )
                .overlay(alignment: .topLeading) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.39, blue: 0.36).opacity(0.20),
                            Color(red: 0.35, green: 0.30, blue: 0.36).opacity(0.10),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                }
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.36, blue: 0.52).opacity(0.28),
                            .clear
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(.white.opacity(0.20), lineWidth: 1)
                )
                .padding(.horizontal, panelHorizontalInset)
                .padding(.vertical, panelVerticalInset)

            VStack(spacing: 14) {
                header
                inputRow
                suggestButton

                tasksSection
                    .padding(.bottom, 8)

                footer
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 14)
            .padding(.horizontal, panelHorizontalInset)
            .padding(.vertical, panelVerticalInset)
        }
        .frame(width: panelWidth, height: panelHeight)
        .padding(.horizontal, windowEdgePaddingX)
        .padding(.vertical, windowEdgePaddingY)
        .background(
            WindowConfigurator(
                targetSize: CGSize(
                    width: panelWidth + (windowEdgePaddingX * 2),
                    height: panelHeight + (windowEdgePaddingY * 2)
                )
            ) { window in
                if hostWindow !== window {
                    hostWindow = window
                }
            }
        )
        .onAppear {
            syncMenuBarTaskList()
            DispatchQueue.main.async {
                isInputFocused = true
            }
        }
        .onChange(of: tasks) { _, _ in
            syncMenuBarTaskList()
        }
        .onChange(of: hostWindowID) { _, _ in
            syncMenuBarTaskList()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(panelTitle)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.97))
                .frame(height: 36, alignment: .center)

            Spacer()

            HStack(spacing: 8) {
                Button(action: {}) {
                    HeaderIcon(symbol: "lightbulb", isActive: true)
                }
                .buttonStyle(.plain)
                .handCursorOnHover()

                Button(action: duplicateTodoWindow) {
                    HeaderIcon(symbol: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .handCursorOnHover()

                HeaderIcon(symbol: "ellipsis")
                Button(action: closeTodoWindow) {
                    HeaderIcon(symbol: "xmark")
                }
                .buttonStyle(.plain)
                .handCursorOnHover()
            }
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField(
                "",
                text: $newTask,
                prompt: Text("Nova tarefa simples...")
                    .foregroundColor(Color.white.opacity(0.70))
            )
            .textFieldStyle(.plain)
            .font(.system(size: 21, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))
            .padding(.leading, 16)
            .focused($isInputFocused)
            .onSubmit(addTask)

            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 46, height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.white.opacity(0.14), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 5)
        }
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.17))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.20), lineWidth: 1.2)
                )
        )
    }

    private var suggestButton: some View {
        HStack {
            Button(action: {}) {
                Label("Sugerir", systemImage: "wand.and.stars")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.black.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(.white.opacity(0.10), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var tasksSection: some View {
        Group {
            if tasks.isEmpty {
                Text("Vazio como o espaco...")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if tasks.count <= maxVisibleTasks {
                LazyVStack(spacing: taskRowSpacing) {
                    ForEach(tasks.indices, id: \.self) { index in
                        taskRow(for: index)
                    }
                }
            } else {
                ScrollView(showsIndicators: true) {
                    LazyVStack(spacing: taskRowSpacing) {
                        ForEach(tasks.indices, id: \.self) { index in
                            taskRow(for: index)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.visible)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: tasksContainerHeight, alignment: .top)
        .overlay(alignment: .topTrailing) {
            if pendingUndo != nil {
                undoFloatingButton
                    .padding(.top, -34)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.16), value: pendingUndo != nil)
    }

    private var undoFloatingButton: some View {
        Button("Desfazer") {
            undoLastCompletion()
        }
        .buttonStyle(.plain)
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.black.opacity(0.26))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
        .handCursorOnHover()
    }

    private func taskRow(for index: Int) -> some View {
        let task = tasks[index]
        let isExpanded = expandedTaskIDs.contains(task.id)

        return HStack(alignment: .center, spacing: 10) {
            Button {
                toggleTask(at: index)
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(task.completed ? .green : .white.opacity(0.50))
            }
            .buttonStyle(.plain)
            .handCursorOnHover()

            if editingTaskID == task.id {
                TextField("", text: $editingTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(maxHeight: .infinity, alignment: .center)
                    .onSubmit {
                        saveTaskEdit(for: task.id)
                    }
            } else {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(task.completed ? .white.opacity(0.50) : .white.opacity(0.88))
                    .strikethrough(task.completed, color: .white.opacity(0.5))
                    .lineLimit(isExpanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: isExpanded)
                    .frame(maxHeight: .infinity, alignment: .center)
            }

            Spacer(minLength: 0)

            if editingTaskID == task.id {
                Button {
                    saveTaskEdit(for: task.id)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .handCursorOnHover()

                Button {
                    cancelTaskEdit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .handCursorOnHover()
            } else {
                TaskRowActionButton(symbol: isExpanded ? "chevron.up" : "chevron.down") {
                    toggleTaskExpansion(for: task.id)
                }

                TaskRowActionButton(symbol: "pencil") {
                    startTaskEdit(for: task.id)
                }

                TaskRowActionButton(symbol: "trash") {
                    deleteTask(at: index)
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: rowHeight(for: task), alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(.white.opacity(0.13))
                .frame(height: 1)

            HStack {
                Text("\(pendingCount) pendentes")
                Spacer()
                Text("\(completionPercent)% concluido")
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.58))
        }
    }

    private func addTask() {
        let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.insert(TodoItem(title: trimmed), at: 0)
        newTask = ""
    }

    private func toggleTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }

        if tasks[index].completed {
            tasks[index].completed = false
            return
        }

        var task = tasks.remove(at: index)
        registerUndo(for: task, originalIndex: index)
        task.completed = true
        tasks.append(task)
    }

    private func registerUndo(for task: TodoItem, originalIndex: Int) {
        undoDismissWorkItem?.cancel()
        pendingUndo = UndoSnapshot(task: task, originalIndex: originalIndex)

        let workItem = DispatchWorkItem {
            pendingUndo = nil
            undoDismissWorkItem = nil
        }
        undoDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }

    private func undoLastCompletion() {
        guard let snapshot = pendingUndo else { return }
        undoDismissWorkItem?.cancel()
        undoDismissWorkItem = nil
        pendingUndo = nil

        guard let currentIndex = tasks.firstIndex(where: { $0.id == snapshot.task.id }) else { return }
        var task = tasks.remove(at: currentIndex)
        task.completed = false
        let insertionIndex = min(snapshot.originalIndex, tasks.count)
        tasks.insert(task, at: insertionIndex)
    }

    private func startTaskEdit(for taskID: UUID) {
        guard let task = tasks.first(where: { $0.id == taskID }) else { return }
        editingTaskID = taskID
        editingTaskTitle = task.title
    }

    private func saveTaskEdit(for taskID: UUID) {
        let trimmed = editingTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        defer { cancelTaskEdit() }
        guard !trimmed.isEmpty else { return }
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].title = trimmed
    }

    private func cancelTaskEdit() {
        editingTaskID = nil
        editingTaskTitle = ""
    }

    private func deleteTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        let removedTask = tasks.remove(at: index)
        expandedTaskIDs.remove(removedTask.id)

        if editingTaskID == removedTask.id {
            cancelTaskEdit()
        }

        guard let snapshot = pendingUndo else { return }

        if snapshot.task.id == removedTask.id {
            undoDismissWorkItem?.cancel()
            undoDismissWorkItem = nil
            pendingUndo = nil
            return
        }

        if index < snapshot.originalIndex {
            pendingUndo = UndoSnapshot(task: snapshot.task, originalIndex: snapshot.originalIndex - 1)
        }
    }

    private func toggleTaskExpansion(for taskID: UUID) {
        if expandedTaskIDs.contains(taskID) {
            expandedTaskIDs.remove(taskID)
        } else {
            expandedTaskIDs.insert(taskID)
        }
    }

    private func rowHeight(for task: TodoItem) -> CGFloat {
        expandedTaskIDs.contains(task.id) ? expandedTaskRowHeight : taskRowHeight
    }

    private func closeTodoWindow() {
        if let window = hostWindow,
           window.identifier?.rawValue == "glassdo.window" {
            TodoWindowStore.shared.prepareForWindowClose()
            TodoWindowStore.shared.unregister(window: window)
            window.orderOut(nil)
            window.close()
            return
        }

        if let window = NSApplication.shared.windows.first(where: {
            $0.identifier?.rawValue == "glassdo.window" && $0.isVisible
        }) {
            TodoWindowStore.shared.prepareForWindowClose()
            TodoWindowStore.shared.unregister(window: window)
            window.orderOut(nil)
            window.close()
        }
    }

    private func duplicateTodoWindow() {
        TodoWindowStore.shared.recordExplicitOpenRequest()
        openWindow(id: "todo-window")
    }

    private func syncMenuBarTaskList() {
        guard let window = hostWindow else { return }
        TodoWindowStore.shared.updateTasks(window: window, tasks: tasks.map(\.title))
    }
}

private struct HandCursorOnHover: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private extension View {
    func handCursorOnHover() -> some View {
        modifier(HandCursorOnHover())
    }
}

private struct HeaderIcon: View {
    let symbol: String
    var isActive: Bool = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white.opacity(isActive ? 0.86 : 0.56))
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(isActive ? Color.indigo.opacity(0.30) : .white.opacity(0.08))
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(isActive ? 0.20 : 0.12), lineWidth: 1)
                    )
            )
    }
}

private struct TaskRowActionButton: View {
    let symbol: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isHovered ? .white.opacity(0.10) : .clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(.white.opacity(isHovered ? 0.16 : 0), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    let targetSize: CGSize
    let onResolve: (NSWindow) -> Void
    private static var patchedWindowClasses: Set<ObjectIdentifier> = []

    init(targetSize: CGSize = CGSize(width: 410, height: 360), onResolve: @escaping (NSWindow) -> Void = { _ in }) {
        self.targetSize = targetSize
        self.onResolve = onResolve
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            configure(window)
            onResolve(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            configure(window)
            onResolve(window)
        }
    }

    private func configure(_ window: NSWindow) {
        ensureWindowCanBecomeKey(window)

        if window.identifier?.rawValue != "glassdo.window" {
            window.identifier = NSUserInterfaceItemIdentifier("glassdo.window")
            window.styleMask = [.borderless, .fullSizeContentView]
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }

        TodoWindowStore.shared.register(window: window)
        window.minSize = NSSize(width: 390, height: 320)
        let desiredSize = NSSize(width: targetSize.width, height: targetSize.height)
        if window.frame.size != desiredSize {
            window.setContentSize(desiredSize)
        }
    }

    private func ensureWindowCanBecomeKey(_ window: NSWindow) {
        guard let windowClass = object_getClass(window) else { return }
        let classID = ObjectIdentifier(windowClass)
        guard !Self.patchedWindowClasses.contains(classID) else { return }

        let canBecomeKey: @convention(block) (AnyObject) -> Bool = { _ in true }
        let canBecomeMain: @convention(block) (AnyObject) -> Bool = { _ in true }

        class_addMethod(
            windowClass,
            #selector(getter: NSWindow.canBecomeKey),
            imp_implementationWithBlock(canBecomeKey),
            "B@:"
        )
        class_addMethod(
            windowClass,
            #selector(getter: NSWindow.canBecomeMain),
            imp_implementationWithBlock(canBecomeMain),
            "B@:"
        )

        Self.patchedWindowClasses.insert(classID)
    }
}
