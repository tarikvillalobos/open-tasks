//
//  ContentView.swift
//  open-tasks
//
//  Created by Tarik Villalobos on 2/16/26.
//

import AppKit
import ObjectiveC.runtime
import SwiftUI

struct ContentView: View {
    @State private var newTask = ""
    @State private var hostWindow: NSWindow?

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
                        .stroke(.white.opacity(0.20), lineWidth: 1)
                )

            VStack(spacing: 18) {
                header
                inputRow
                suggestButton

                Spacer(minLength: 0)

                Text("Vazio como o espaco...")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(.bottom, 8)

                Spacer(minLength: 0)

                footer
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 14)
        }
        .frame(width: 410, height: 360)
        .background(
            WindowConfigurator { window in
                if hostWindow !== window {
                    hostWindow = window
                }
            }
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text("OpenTasks")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.97))
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: {}) {
                    HeaderIcon(symbol: "lightbulb", isActive: true)
                }
                .buttonStyle(.plain)
                .handCursorOnHover()

                Button(action: {}) {
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
            .padding(.top, 2)
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

            Button(action: {}) {
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

    private var footer: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(.white.opacity(0.13))
                .frame(height: 1)

            HStack {
                Text("0 pendentes")
                Spacer()
                Text("0% concluido")
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.58))
        }
    }

    private func closeTodoWindow() {
        if let window = hostWindow {
            window.orderOut(nil)
            window.close()
            return
        }

        if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
            window.orderOut(nil)
            window.close()
        }
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

private struct WindowConfigurator: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    init(onResolve: @escaping (NSWindow) -> Void = { _ in }) {
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
        guard window.identifier?.rawValue != "glassdo.window" else { return }
        if !(window is KeyableBorderlessWindow) {
            _ = object_setClass(window, KeyableBorderlessWindow.self)
        }
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
        window.minSize = NSSize(width: 390, height: 320)
        window.setContentSize(NSSize(width: 410, height: 360))
        window.makeKeyAndOrderFront(nil)
    }
}

private final class KeyableBorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
