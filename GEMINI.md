# Project Context: Flow Workspace

## Project Overview
**PomoFlow** is a cross-platform Pomodoro timer application built with Flutter. It focuses on a modern, high-performance user experience featuring a Glassmorphism UI design.

**Key Features:**
- **Pomodoro Timer**: Core focus/break timer functionality.
- **Layout Modes**: "Default" and "Gallery" layouts for different visual preferences.
- **UI Customization**: Adjustable UI opacity, font selection, and theme modes (Light/Dark/System).
- **Sound**: Custom alarm and ambient sound support (`audioplayers`).
- **Notifications**: System notifications for timer events (`flutter_local_notifications`).
- **Android Widget**: 
  - Real-time timer display with circular progress indicator
  - Smart pause control (only available during Focus mode, hidden during breaks)
  - Performance-optimized with state caching to prevent UI flickering
  - Syncs colors and background settings from main app
- **Window Control**: "Always on Top" and other window management features (`window_manager`).
- **Performance**: High-resolution image caching, memory optimization, and persistent background storage.
- **Platforms**: Android, iOS, macOS, Windows.

## Environment
- **Operating System**: darwin (macOS)
- **Framework**: Flutter (Dart SDK >=3.10.1)

## Tech Stack
- **Languages**: Dart, Kotlin (Android), Swift (iOS/macOS).
- **State Management**: `provider`.
- **Storage**: `shared_preferences`, `path_provider`.
- **Audio**: `audioplayers`.
- **Widgets**: `home_widget` (Android home screen widget with RemoteViews).
- **Desktop Utils**: `window_manager`.
- **Plugins**: `flutter_launcher_icons`, `flutter_colorpicker`, `file_picker`.

## Development Conventions
- **Assets**:
  - Sounds located in `assets/sounds/`.
  - App icons generated from `logo.png` using `flutter_launcher_icons`.
- **Build**:
  - Run `flutter pub get` after pulling changes.
  - Run `dart run flutter_launcher_icons` to update icons manifest.
- **Code Style**:
  - Follow Flutter lints (`flutter_lints`).
