//
//  ContentView.swift
//  open-tasks
//
//  Created by Tarik Villalobos on 2/16/26.
//

import AppKit
import SwiftUI

struct TodoItem: Identifiable {
    let id = UUID()
    var title: String
    var completed: Bool = false
    var tag: String? = "IA"
}

struct ContentView: View {
    @State private var newTask = ""
    @State private var tasks: [TodoItem] = [
        TodoItem(title: "Create your profile"),
        TodoItem(title: "Explore the dashboard"),
        TodoItem(title: "Add your first task"),
        TodoItem(title: "Bem-vindo ao GlassDo", tag: nil),
        TodoItem(title: "Arraste esta janela", completed: true, tag: nil),
        TodoItem(title: "Duplique-me no icone acima", tag: nil)
    ]

    private var pendingCount: Int { tasks.filter { !$0.completed }.count }
    private var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.completed).count) / Double(tasks.count)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                )
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color.orange.opacity(0.20), Color.purple.opacity(0.17), .clear],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                }
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.28), Color.blue.opacity(0.18), .clear],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                }

            VStack(spacing: 12) {
                header
                inputRow
                suggestButton
                tasksList
                footer
            }
            .padding(18)
        }
        .frame(width: 430, height: 760)
        .background(WindowConfigurator())
        .padding(8)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("GlassDo")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Text("IOS 26 CONCEPT")
                    .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                    .kerning(0.9)
                    .foregroundStyle(.white.opacity(0.56))
            }
            Spacer()
            HStack(spacing: 8) {
                HeaderIcon(symbol: "lightbulb", isActive: true)
                HeaderIcon(symbol: "doc.on.doc")
                HeaderIcon(symbol: "ellipsis")
                HeaderIcon(symbol: "xmark")
            }
        }
        .padding(.top, 4)
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("Nova tarefa simples...", text: $newTask)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.leading, 16)

            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.system(size: 21, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(.white.opacity(0.92))
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 5)
        }
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.32))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var suggestButton: some View {
        HStack {
            Button {
                newTask = "Focar na tarefa mais importante de hoje"
            } label: {
                Label("Sugerir", systemImage: "wand.and.stars")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white.opacity(0.9))
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(.black.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(.white.opacity(0.14), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }

    private var tasksList: some View {
        ScrollView(showsIndicators: true) {
            LazyVStack(spacing: 10) {
                ForEach(tasks.indices, id: \.self) { index in
                    taskRow(for: index)
                }
            }
            .padding(.trailing, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func taskRow(for index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.2))
                .padding(.top, 6)

            Button {
                tasks[index].completed.toggle()
            } label: {
                Image(systemName: tasks[index].completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(tasks[index].completed ? .green : .white.opacity(0.35))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                Text(tasks[index].title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(tasks[index].completed ? .white.opacity(0.44) : .white.opacity(0.92))
                    .strikethrough(tasks[index].completed, color: .white.opacity(0.45))
                    .lineLimit(1)
                if let tag = tasks[index].tag {
                    Text(tag)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.purple.opacity(0.38))
                        )
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(minHeight: 98)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(tasks[index].completed ? 0.17 : 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)

            HStack {
                Text("\(pendingCount) pendentes")
                Spacer()
                Text("\(Int(progress * 100))% concluido")
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.48))
        }
    }

    private func addTask() {
        let trimmed = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.insert(TodoItem(title: trimmed, tag: nil), at: 0)
        newTask = ""
    }
}

private struct HeaderIcon: View {
    let symbol: String
    var isActive: Bool = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(isActive ? 0.85 : 0.62))
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(isActive ? Color.indigo.opacity(0.32) : .white.opacity(0.08))
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(isActive ? 0.22 : 0.15), lineWidth: 1)
                    )
            )
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            configure(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            configure(window)
        }
    }

    private func configure(_ window: NSWindow) {
        guard window.identifier?.rawValue != "glassdo.window" else { return }
        window.identifier = NSUserInterfaceItemIdentifier("glassdo.window")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.styleMask.insert(.fullSizeContentView)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.minSize = NSSize(width: 390, height: 620)
        window.setContentSize(NSSize(width: 430, height: 760))
    }
}
