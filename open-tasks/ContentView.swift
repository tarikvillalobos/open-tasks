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
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .overlay(alignment: .top) {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.35), Color.purple.opacity(0.20), .clear],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                }

            VStack(spacing: 14) {
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
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Text("IOS 26 CONCEPT")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .kerning(1.4)
                    .foregroundStyle(.white.opacity(0.56))
            }
            Spacer()
            HStack(spacing: 8) {
                HeaderIcon(symbol: "lightbulb")
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
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.leading, 20)

            Button(action: addTask) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .frame(width: 58, height: 58)
                    .foregroundStyle(.white.opacity(0.92))
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
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
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white.opacity(0.9))
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.black.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
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
            .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func taskRow(for index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.2))
                .padding(.top, 6)

            Button {
                tasks[index].completed.toggle()
            } label: {
                Image(systemName: tasks[index].completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(tasks[index].completed ? .green : .white.opacity(0.35))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                Text(tasks[index].title)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(tasks[index].completed ? .white.opacity(0.44) : .white.opacity(0.92))
                    .strikethrough(tasks[index].completed, color: .white.opacity(0.45))
                    .lineLimit(2)
                if let tag = tasks[index].tag {
                    Text(tag)
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(.purple.opacity(0.38))
                        )
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(tasks[index].completed ? 0.15 : 0.24))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
            .font(.system(size: 28, weight: .bold, design: .rounded))
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

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 52, height: 52)
            .background(
                Circle()
                    .fill(.white.opacity(0.08))
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 1)
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
