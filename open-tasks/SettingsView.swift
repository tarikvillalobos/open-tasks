//
//  SettingsView.swift
//  open-tasks
//

import AppKit
import ObjectiveC.runtime
import SwiftUI

struct SettingsView: View {
    private enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "Geral"
        case appearance = "Aparência"
        case codexCLI = "Codex CLI"
        case shortcuts = "Atalhos"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general:
                return "slider.horizontal.3"
            case .appearance:
                return "desktopcomputer"
            case .codexCLI:
                return "chevron.left.forwardslash.chevron.right"
            case .shortcuts:
                return "command"
            }
        }
    }

    private enum ThemeMode: String, CaseIterable, Identifiable {
        case light = "Clara"
        case dark = "Escura"
        case automatic = "Automática"

        var id: String { rawValue }
    }

    private enum IconSizeOption: String, CaseIterable, Identifiable {
        case small = "Pequeno"
        case medium = "Médio"
        case large = "Grande"

        var id: String { rawValue }
    }

    private enum ScrollbarBehavior: String, CaseIterable, Identifiable {
        case automatic = "Automático"
        case whileScrolling = "Ao rolar"
        case always = "Sempre"

        var id: String { rawValue }
    }

    private struct ShortcutItem: Identifiable {
        let id = UUID()
        let name: String
        let keys: [String]
    }

    private struct ShortcutGroup: Identifiable {
        let id = UUID()
        let title: String
        let items: [ShortcutItem]
    }

    private let panelWidth: CGFloat = 760
    private let panelHeight: CGFloat = 640
    private let panelHorizontalInset: CGFloat = 2
    private let panelVerticalInset: CGFloat = 6
    private let windowEdgePaddingX: CGFloat = 10
    private let windowEdgePaddingY: CGFloat = 12

    @State private var selectedTab: SettingsTab = .general
    @State private var searchText = ""
    @State private var hostWindow: NSWindow?

    @State private var launchAtLogin = false
    @State private var reopenPreviousWindows = true
    @State private var playCompletionSound = true
    @State private var hapticsEnabled = true
    @State private var appLanguage = "Português (Brasil)"

    @State private var selectedTheme: ThemeMode = .dark
    @State private var selectedAccentColorIndex = 0
    @State private var selectedIconSize: IconSizeOption = .medium
    @State private var selectedScrollbarBehavior: ScrollbarBehavior = .automatic

    @State private var selectedModel = "Gemini 1.5 Pro"
    @State private var temperature = 0.7
    @State private var terminalSuggestionsEnabled = true
    @State private var automaticErrorAnalysis = false
    @State private var syncProfilesEnabled = true

    private let executablePath = "/usr/local/bin/codex"
    private let apiKeyMasked = "••••••••••••••••"
    private let models = ["Gemini 1.5 Pro", "GPT-4.1", "Claude 3.7 Sonnet"]

    private var accentPalette: [Color] {
        [
            Color(red: 0.39, green: 0.44, blue: 0.99),
            Color(red: 0.30, green: 0.53, blue: 0.98),
            Color(red: 0.55, green: 0.35, blue: 0.88),
            Color(red: 0.83, green: 0.30, blue: 0.62),
            Color(red: 0.88, green: 0.29, blue: 0.33),
            Color(red: 0.90, green: 0.47, blue: 0.19),
            Color(red: 0.23, green: 0.73, blue: 0.41)
        ]
    }

    private var shortcutGroups: [ShortcutGroup] {
        [
            ShortcutGroup(
                title: "GERAL",
                items: [
                    ShortcutItem(name: "Nova Tarefa", keys: ["↩"]),
                    ShortcutItem(name: "Configurações", keys: ["⌘", ","]),
                    ShortcutItem(name: "Buscar", keys: ["⌘", "F"])
                ]
            ),
            ShortcutGroup(
                title: "JANELA",
                items: [
                    ShortcutItem(name: "Duplicar Janela", keys: ["⌘", "D"]),
                    ShortcutItem(name: "Fechar Janela", keys: ["⌘", "W"]),
                    ShortcutItem(name: "Minimizar", keys: ["⌘", "M"])
                ]
            ),
            ShortcutGroup(
                title: "TAREFAS",
                items: [
                    ShortcutItem(name: "Editar Tarefa", keys: ["⌘", "E"]),
                    ShortcutItem(name: "Concluir Tarefa", keys: ["⌘", "↩"]),
                    ShortcutItem(name: "Excluir Tarefa", keys: ["⌘", "⌫"])
                ]
            )
        ]
    }

    private var visibleTabs: [SettingsTab] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return SettingsTab.allCases
        }
        return SettingsTab.allCases.filter { tab in
            tab.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var activeTab: SettingsTab {
        if visibleTabs.contains(selectedTab) {
            return selectedTab
        }
        return visibleTabs.first ?? .general
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
                settingsWorkspace
                footer
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 14)
            .padding(.horizontal, panelHorizontalInset)
            .padding(.vertical, panelVerticalInset)
            .overlay(alignment: .top) {
                SettingsWindowDragRegion()
                    .frame(maxWidth: .infinity)
                    .frame(height: 12)
            }
        }
        .frame(width: panelWidth, height: panelHeight)
        .padding(.horizontal, windowEdgePaddingX)
        .padding(.vertical, windowEdgePaddingY)
        .background(
            SettingsWindowConfigurator(
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
    }

    private var settingsWorkspace: some View {
        HStack(alignment: .top, spacing: 14) {
            sidebar

            Rectangle()
                .fill(.white.opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 8)

            contentScroll
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 0) {
                Text("Config")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.97))
                    .frame(height: 36, alignment: .center)

                Spacer()
            }
            .frame(height: 36)
            .background(SettingsWindowDragRegion())

            HStack(spacing: 8) {
                Button(action: {}) {
                    SettingsHeaderIcon(symbol: "gearshape", isActive: true)
                }
                .buttonStyle(.plain)
                .disabled(true)

                SettingsHeaderIcon(symbol: activeTab.icon)

                SettingsHeaderIcon(symbol: "ellipsis")

                Button(action: closeSettingsWindow) {
                    SettingsHeaderIcon(symbol: "xmark")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.56))
                .frame(width: 20)

            TextField(
                "",
                text: $searchText,
                prompt: Text("Buscar ajustes...").foregroundColor(.white.opacity(0.70))
            )
            .textFieldStyle(.plain)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.92))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.17))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.20), lineWidth: 1.2)
                )
        )
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            searchRow
            sidebarTabs
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(width: 220)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var sidebarTabs: some View {
        Group {
            if visibleTabs.isEmpty {
                EmptySettingsStateView()
            } else {
                VStack(spacing: 8) {
                    ForEach(visibleTabs) { tab in
                        sidebarTabButton(tab)
                    }
                }
            }
        }
    }

    private func sidebarTabButton(_ tab: SettingsTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 9) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 16)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white.opacity(activeTab == tab ? 0.95 : 0.72))
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(activeTab == tab ? Color(red: 0.39, green: 0.41, blue: 0.93).opacity(0.40) : .black.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(.white.opacity(activeTab == tab ? 0.22 : 0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var contentScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                switch activeTab {
                case .general:
                    generalContent
                case .appearance:
                    appearanceContent
                case .codexCLI:
                    codexContent
                case .shortcuts:
                    shortcutsContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(.white.opacity(0.14))
                .frame(height: 1)

            HStack {
                Text("Configuração ativa")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))

                Spacer()

                Text(activeTab.rawValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
            }
        }
    }

    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("INICIALIZAÇÃO")
            settingsCard {
                toggleRow(icon: "power", title: "Iniciar ao ligar o Mac", isOn: $launchAtLogin)
                rowDivider
                toggleRow(title: "Reabrir janelas anteriores", isOn: $reopenPreviousWindows)
            }

            sectionTitle("SONS E FEEDBACK")
            settingsCard {
                toggleRow(icon: "speaker.wave.2", title: "Reproduzir som ao concluir", isOn: $playCompletionSound)
                rowDivider
                toggleRow(title: "Feedback tátil (Haptics)", isOn: $hapticsEnabled)
            }

            sectionTitle("IDIOMA")
            settingsCard {
                HStack(spacing: 12) {
                    Text("Idioma do App")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    Picker("", selection: $appLanguage) {
                        Text("Português (Brasil)").tag("Português (Brasil)")
                        Text("English (US)").tag("English (US)")
                        Text("Español").tag("Español")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 220)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            sectionTitle("DADOS")
            settingsCard {
                HStack(spacing: 10) {
                    Text("Armazenamento Local")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    Text("2.4 GB")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    private var appearanceContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("TEMA")
            HStack(spacing: 10) {
                ForEach(ThemeMode.allCases) { mode in
                    Button {
                        selectedTheme = mode
                    } label: {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(themePreviewBackground(for: mode))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(mode == selectedTheme ? Color(red: 0.44, green: 0.45, blue: 0.98) : .white.opacity(0.16), lineWidth: mode == selectedTheme ? 2 : 1)
                                )
                                .frame(height: 76)
                                .overlay(themePreviewContent(for: mode))

                            Text(mode.rawValue)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            sectionTitle("COR DE DESTAQUE")
            HStack(spacing: 10) {
                ForEach(accentPalette.indices, id: \.self) { index in
                    Button {
                        selectedAccentColorIndex = index
                    } label: {
                        Circle()
                            .fill(accentPalette[index])
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(index == selectedAccentColorIndex ? 0.95 : 0), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            sectionTitle("TAMANHO DOS ÍCONES")
            HStack(spacing: 8) {
                ForEach(IconSizeOption.allCases) { size in
                    Button {
                        selectedIconSize = size
                    } label: {
                        Text(size.rawValue)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(selectedIconSize == size ? 0.95 : 0.62))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedIconSize == size ? .white.opacity(0.20) : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.black.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )

            sectionTitle("BARRAS DE ROLAGEM")
            settingsCard {
                ForEach(ScrollbarBehavior.allCases.indices, id: \.self) { index in
                    let behavior = ScrollbarBehavior.allCases[index]
                    Button {
                        selectedScrollbarBehavior = behavior
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .stroke(.white.opacity(0.58), lineWidth: 1.6)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .fill(Color(red: 0.39, green: 0.44, blue: 0.99))
                                        .frame(width: 10, height: 10)
                                        .opacity(selectedScrollbarBehavior == behavior ? 1 : 0)
                                )

                            Text(behavior.rawValue)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.86))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    if index < ScrollbarBehavior.allCases.count - 1 {
                        rowDivider
                    }
                }
            }
        }
    }

    private var codexContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("CONEXÃO")
            settingsCard {
                rowValue(title: "Caminho do Executável", value: executablePath)
                rowDivider
                rowValue(title: "Chave de API", value: apiKeyMasked)
            }

            Text("O caminho deve apontar para o binário instalado via Homebrew ou npm.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .padding(.horizontal, 2)

            sectionTitle("INFERÊNCIA")
            settingsCard {
                HStack {
                    Text("Modelo Principal")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    Picker("", selection: $selectedModel) {
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 210)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                HStack(spacing: 10) {
                    Text("Temperatura")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    Slider(value: $temperature, in: 0...1, step: 0.1)
                        .tint(Color(red: 0.39, green: 0.44, blue: 0.99))

                    Text(String(format: "%.1f", temperature))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(width: 32)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }

            sectionTitle("INTEGRAÇÃO")
            settingsCard {
                toggleRow(title: "Sugestões Inteligentes no Terminal", isOn: $terminalSuggestionsEnabled)
                rowDivider
                toggleRow(title: "Análise de Erros Automática", isOn: $automaticErrorAnalysis)
                rowDivider
                toggleRow(title: "Sincronizar Perfis", isOn: $syncProfilesEnabled)
            }
        }
    }

    private var shortcutsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(shortcutGroups) { group in
                sectionTitle(group.title)
                settingsCard {
                    ForEach(group.items.indices, id: \.self) { index in
                        let item = group.items[index]
                        HStack {
                            Text(item.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.88))

                            Spacer()

                            ShortcutKeysView(keys: item.keys)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)

                        if index < group.items.count - 1 {
                            rowDivider
                        }
                    }
                }
            }
        }
    }

    private func rowValue(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.40))
            .tracking(0.7)
            .padding(.top, 2)
    }

    private func toggleRow(icon: String? = nil, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(width: 20)
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color(red: 0.39, green: 0.44, blue: 0.99))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.10))
            .frame(height: 1)
            .padding(.horizontal, 12)
    }

    private func themePreviewBackground(for mode: ThemeMode) -> AnyShapeStyle {
        switch mode {
        case .light:
            return AnyShapeStyle(Color.white.opacity(0.90))
        case .dark:
            return AnyShapeStyle(Color.black.opacity(0.76))
        case .automatic:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.white.opacity(0.84), .black.opacity(0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    @ViewBuilder
    private func themePreviewContent(for mode: ThemeMode) -> some View {
        switch mode {
        case .light:
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.black.opacity(0.10))
                    .frame(width: 92, height: 12)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.black.opacity(0.08))
                    .frame(width: 70, height: 8)
            }
        case .dark:
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .frame(width: 92, height: 12)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.white.opacity(0.10))
                    .frame(width: 70, height: 8)
            }
        case .automatic:
            Text("Auto")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.90))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.14))
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.20), lineWidth: 1)
                        )
                )
        }
    }

    private func closeSettingsWindow() {
        hostWindow?.close()
    }
}

private struct SettingsHeaderIcon: View {
    let symbol: String
    var isActive = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white.opacity(isActive ? 0.95 : 0.72))
            .frame(width: 42, height: 42)
            .background(
                Circle()
                    .fill(isActive ? Color(red: 0.42, green: 0.41, blue: 0.80).opacity(0.75) : .white.opacity(0.06))
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )
            )
    }
}

private struct ShortcutKeysView: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(minWidth: 26)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(.white.opacity(0.12), lineWidth: 1)
                            )
                    )
            }
        }
    }
}

private struct EmptySettingsStateView: View {
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.52))
            Text("Nenhum ajuste encontrado")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
        }
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private struct SettingsWindowConfigurator: NSViewRepresentable {
    let targetSize: CGSize
    let onResolve: (NSWindow) -> Void
    private static var patchedWindowClasses: Set<ObjectIdentifier> = []

    init(targetSize: CGSize, onResolve: @escaping (NSWindow) -> Void = { _ in }) {
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

        if window.identifier?.rawValue != "glassdo.settings.window" {
            window.identifier = NSUserInterfaceItemIdentifier("glassdo.settings.window")
            window.styleMask = [.borderless, .fullSizeContentView]
            window.isMovableByWindowBackground = false
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.level = .floating
            window.collectionBehavior = [.fullScreenAuxiliary]
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }

        window.minSize = NSSize(width: 620, height: 520)
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

private struct SettingsWindowDragRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        SettingsDragRegionNSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class SettingsDragRegionNSView: NSView {
    override func resetCursorRects() {
        super.resetCursorRects()
        discardCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        NSCursor.closedHand.push()
        defer { NSCursor.pop() }
        window?.performDrag(with: event)
    }
}
