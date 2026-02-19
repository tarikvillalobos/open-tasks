//
//  SettingsView.swift
//  open-tasks
//

import SwiftUI

struct SettingsView: View {
    private enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "Geral"
        case appearance = "Aparência"
        case codexCLI = "Codex CLI"
        case shortcuts = "Atalhos do Teclado"

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
        case automatic = "Automaticamente com base no mouse ou trackpad"
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

    @State private var selectedTab: SettingsTab = .general
    @State private var searchText = ""

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
                    ShortcutItem(name: "Nova Ideia", keys: ["⌘", "I"]),
                    ShortcutItem(name: "Configurações", keys: ["⌘", ","])
                ]
            ),
            ShortcutGroup(
                title: "GERENCIAMENTO DE JANELAS",
                items: [
                    ShortcutItem(name: "Duplicar Janela", keys: ["⌘", "D"]),
                    ShortcutItem(name: "Fechar Janela", keys: ["⌘", "W"]),
                    ShortcutItem(name: "Minimizar", keys: ["⌘", "M"])
                ]
            ),
            ShortcutGroup(
                title: "EDIÇÃO",
                items: [
                    ShortcutItem(name: "Editar Tarefa", keys: ["⌘", "E"]),
                    ShortcutItem(name: "Marcar como Concluída", keys: ["⌘", "↩"]),
                    ShortcutItem(name: "Excluir Tarefa", keys: ["⌘", "⌫"])
                ]
            )
        ]
    }

    private var visibleTabs: [SettingsTab] {
        guard !searchText.isEmpty else { return SettingsTab.allCases }
        return SettingsTab.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.23, green: 0.17, blue: 0.34),
                    Color(red: 0.16, green: 0.16, blue: 0.42),
                    Color(red: 0.21, green: 0.13, blue: 0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {
                sidebar

                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1)

                detailPanel
            }
            .background(Color.black.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .padding(18)
        }
        .frame(minWidth: 1240, minHeight: 780)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))

                TextField("Buscar Ajustes", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.13), lineWidth: 1)
                    )
            )

            VStack(spacing: 8) {
                if visibleTabs.isEmpty {
                    Text("Nenhum ajuste encontrado")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.52))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                } else {
                    ForEach(visibleTabs) { tab in
                        tabButton(tab)
                    }
                }
            }

            Spacer(minLength: 12)

            Rectangle()
                .fill(.white.opacity(0.11))
                .frame(height: 1)

            HStack(spacing: 14) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(red: 0.32, green: 0.41, blue: 0.90))
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(Color(red: 0.18, green: 0.25, blue: 0.45).opacity(0.55))
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.12), lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Usuário Glass")
                        .font(.system(size: 33, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.90))

                    Text("Apple Account")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(width: 398)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.18, blue: 0.30),
                    Color(red: 0.11, green: 0.19, blue: 0.27)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func tabButton(_ tab: SettingsTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 14) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 32)

                Text(tab.rawValue)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                Spacer(minLength: 0)
            }
            .foregroundStyle(.white.opacity(selectedTab == tab ? 0.95 : 0.72))
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(selectedTab == tab ? Color(red: 0.39, green: 0.41, blue: 0.93) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(selectedTab == tab ? .white.opacity(0.14) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var detailPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text(selectedTab.rawValue)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 22)

            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    switch selectedTab {
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
                .padding(.horizontal, 30)
                .padding(.top, 26)
                .padding(.bottom, 34)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.24, blue: 0.39),
                    Color(red: 0.18, green: 0.15, blue: 0.37)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 30) {
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

            sectionTitle("IDIOMA E REGIÃO")
            settingsCard {
                HStack(spacing: 14) {
                    Image(systemName: "globe")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(width: 34)

                    Text("Idioma do App")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    Picker("", selection: $appLanguage) {
                        Text("Português (Brasil)").tag("Português (Brasil)")
                        Text("English (US)").tag("English (US)")
                        Text("Español").tag("Español")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 270)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            sectionTitle("DADOS")
            settingsCard {
                HStack {
                    Text("Armazenamento Local")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    Text("2.4 GB")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.66))

                    Button("Limpar") {}
                        .buttonStyle(.bordered)
                        .tint(.red.opacity(0.42))
                        .controlSize(.regular)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
    }

    private var appearanceContent: some View {
        VStack(alignment: .leading, spacing: 30) {
            sectionTitle("APARÊNCIA")

            HStack(spacing: 18) {
                ForEach(ThemeMode.allCases) { mode in
                    Button {
                        selectedTheme = mode
                    } label: {
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(themePreviewBackground(for: mode))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(mode == selectedTheme ? Color(red: 0.44, green: 0.45, blue: 0.98) : .white.opacity(0.18), lineWidth: mode == selectedTheme ? 3 : 1)
                                )
                                .frame(width: 170, height: 112)
                                .overlay(themePreviewContent(for: mode))

                            Text(mode.rawValue)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.78))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            sectionTitle("COR DE DESTAQUE")
            HStack(spacing: 16) {
                ForEach(accentPalette.indices, id: \.self) { index in
                    Button {
                        selectedAccentColorIndex = index
                    } label: {
                        Circle()
                            .fill(accentPalette[index])
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(index == selectedAccentColorIndex ? 0.95 : 0), lineWidth: 3)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 8, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }

            sectionTitle("TAMANHO DOS ÍCONES")
            HStack(spacing: 0) {
                ForEach(IconSizeOption.allCases) { size in
                    Button {
                        selectedIconSize = size
                    } label: {
                        Text(size.rawValue)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(selectedIconSize == size ? 0.94 : 0.62))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(selectedIconSize == size ? .white.opacity(0.20) : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.black.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .frame(maxWidth: 700)

            sectionTitle("BARRAS DE ROLAGEM")
            settingsCard {
                ForEach(ScrollbarBehavior.allCases.indices, id: \.self) { index in
                    let behavior = ScrollbarBehavior.allCases[index]
                    Button {
                        selectedScrollbarBehavior = behavior
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .stroke(.white.opacity(0.58), lineWidth: 2)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .fill(Color(red: 0.39, green: 0.44, blue: 0.99))
                                        .frame(width: 16, height: 16)
                                        .opacity(selectedScrollbarBehavior == behavior ? 1 : 0)
                                )

                            Text(behavior.rawValue)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.86))

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
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
        VStack(alignment: .leading, spacing: 30) {
            sectionTitle("CONEXÃO DO TERMINAL")
            settingsCard {
                HStack {
                    Text("Caminho do Executável")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))

                    Spacer()

                    Text(executablePath)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                rowDivider

                HStack {
                    Text("Chave de API (Opcional)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))

                    Spacer()

                    Text(apiKeyMasked)
                        .font(.system(size: 19, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.58))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }

            Text("O caminho deve apontar para o binário instalado via Homebrew ou npm.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))

            sectionTitle("PARÂMETROS DE INFERÊNCIA")
            settingsCard {
                HStack {
                    Text("Modelo Principal")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    Picker("", selection: $selectedModel) {
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 240)
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 12)

                HStack(spacing: 14) {
                    Text("Temperatura")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    Slider(value: $temperature, in: 0...1, step: 0.1)
                        .tint(Color(red: 0.39, green: 0.44, blue: 0.99))

                    Text(String(format: "%.1f", temperature))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(width: 42)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }

            sectionTitle("INTEGRAÇÃO & SINCRONIZAÇÃO")
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
        VStack(alignment: .leading, spacing: 30) {
            ForEach(shortcutGroups) { group in
                VStack(alignment: .leading, spacing: 16) {
                    sectionTitle(group.title)
                    settingsCard {
                        ForEach(group.items.indices, id: \.self) { index in
                            let item = group.items[index]
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.88))

                                Spacer()

                                ShortcutKeysView(keys: item.keys)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)

                            if index < group.items.count - 1 {
                                rowDivider
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.40))
            .tracking(0.8)
    }

    private func toggleRow(icon: String? = nil, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .frame(width: 34)
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color(red: 0.39, green: 0.44, blue: 0.99))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    private func themePreviewBackground(for mode: ThemeMode) -> AnyShapeStyle {
        switch mode {
        case .light:
            return AnyShapeStyle(Color.white.opacity(0.86))
        case .dark:
            return AnyShapeStyle(Color.black.opacity(0.72))
        case .automatic:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.white.opacity(0.84), .black.opacity(0.78)],
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
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.black.opacity(0.10))
                    .frame(width: 120, height: 18)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.black.opacity(0.08))
                    .frame(width: 90, height: 12)
            }
        case .dark:
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.white.opacity(0.12))
                    .frame(width: 120, height: 18)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.white.opacity(0.10))
                    .frame(width: 90, height: 12)
            }
        case .automatic:
            Text("Auto")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
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
}

private struct ShortcutKeysView: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(minWidth: 36)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(.white.opacity(0.12), lineWidth: 1)
                            )
                    )
            }
        }
    }
}
