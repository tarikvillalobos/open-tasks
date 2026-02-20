# OpenTasks

OpenTasks is a macOS menu bar app for creating and managing task lists in floating glass-style windows.

## Current Status

- Runs as a `MenuBarExtra` app (no Dock icon).
- Supports multiple task windows (`OpenTask`).
- Includes a `Config` screen with a sidebar.

## Features

- Open multiple task windows.
- Add tasks using the input field and `+` button.
- Mark tasks as completed.
- Edit task titles.
- Delete tasks.
- Expand/collapse task rows.
- Reorder tasks via drag and drop using the handle.
- Reordering is blocked for completed tasks.
- Temporary `Undo` action after completing a task.
- Footer counters (`pending` and `% completed`).
- Window dragging only from the dedicated top drag region.
- Open config from the menu (`Config`) and from the gear icon in the OpenTask header.

## Menu Bar Management

- `Open Another` to create a new window.
- List of open windows.
- Show/hide each listed window.
- Rename a window.
- Close an individual window.
- `Close All Open`.
- Open `Config`.
- `Quit`.

## Config Screen

- Sidebar options: `General`, `Appearance`, `Codex CLI`, and `Shortcuts`.
- Search field to filter sidebar options.
- Selected section content displayed in the main panel.

## Temporarily Disabled

- `Suggest` button in OpenTask.
- Lightbulb button in the OpenTask header.

## Technical Notes

- Task state is in-memory only (no file/database persistence yet).
- Config options currently use local UI state (no permanent persistence yet).

## Running the App

### Xcode

1. Open `open-tasks.xcodeproj`.
2. Select the `open-tasks` scheme.
3. Run on `My Mac`.

### Command Line

```bash
xcodebuild -project open-tasks.xcodeproj -scheme open-tasks -destination 'platform=macOS' build
```

## Main Structure

- `open-tasks/open_tasksApp.swift`: entrypoint, scenes, and menu bar.
- `open-tasks/ContentView.swift`: main task window.
- `open-tasks/SettingsView.swift`: config screen.

## License

See `LICENSE`.
