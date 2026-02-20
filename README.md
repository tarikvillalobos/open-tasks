# OpenTasks

OpenTasks é um app macOS de barra de menu para criar e gerenciar listas de tarefas em janelas flutuantes com visual glass.

## Estado Atual

- App roda como `MenuBarExtra` (sem ícone no Dock).
- Suporta múltiplas janelas de tarefas (`OpenTask`).
- Possui tela de configuração (`Config`) com sidebar lateral.

## Funcionalidades

- Abrir múltiplas janelas de tarefas.
- Adicionar tarefa nova pelo input e botão `+`.
- Marcar tarefa como concluída.
- Editar título da tarefa.
- Excluir tarefa.
- Expandir/recolher linha da tarefa.
- Reordenar tarefas por drag and drop usando o handle.
- Bloqueio de reordenação para tarefas já concluídas.
- Ação de `Undo` ao concluir tarefa (temporária).
- Contadores no rodapé (`pendentes` e `% concluído`).
- Janela arrastável apenas na região de drag do topo.
- Abertura da tela de config pelo menu (`Config`) e pelo ícone de engrenagem no header da OpenTask.

## Gestão Via Menu Bar

- `Open Another` para criar nova janela.
- Lista das janelas abertas.
- Mostrar/ocultar janela da lista.
- Renomear janela.
- Fechar janela individual.
- `Close All Open`.
- Abrir `Config`.
- `Quit`.

## Tela de Config

- Sidebar com opções `Geral`, `Aparência`, `Codex CLI` e `Atalhos`.
- Campo de busca para filtrar opções da sidebar.
- Conteúdo da seção selecionada exibido na área principal.

## Recursos Temporariamente Desabilitados

- Botão `Sugerir` na OpenTask.
- Botão da lâmpada no header da OpenTask.

## Observações Técnicas

- Estado das tarefas é em memória (não há persistência em arquivo/banco atualmente).
- Opções da tela de config estão em estado local de UI (sem persistência definitiva).

## Como Rodar

### Xcode

1. Abra `open-tasks.xcodeproj`.
2. Selecione o scheme `open-tasks`.
3. Rode no destino `My Mac`.

### Linha de comando

```bash
xcodebuild -project open-tasks.xcodeproj -scheme open-tasks -destination 'platform=macOS' build
```

## Estrutura Principal

- `open-tasks/open_tasksApp.swift`: entrypoint, scenes e menu bar.
- `open-tasks/ContentView.swift`: janela principal de tarefas.
- `open-tasks/SettingsView.swift`: tela de configuração.

## Licença

Consulte `LICENSE`.
