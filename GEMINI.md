# Project Context: Flow Workspace

## Project Overview
**PomoFlow** is a cross-platform Pomodoro timer application built with Flutter. It focuses on a modern, high-performance user experience featuring a Glassmorphism UI design.

**Key Features:**
- **Pomodoro Timer**: Core focus/break timer functionality.
- **UI Design**: Modern Glassmorphism aesthetic.
- **Sound**: Custom alarm and ambient sound support (`audioplayers`).
- **Notifications**: System notifications for timer events (`flutter_local_notifications`).
- **Window Control**: "Always on Top" and other window management features (`window_manager`).
- **Platforms**: Android, iOS, macOS, Windows.

## Environment
- **Operating System**: darwin (macOS)
- **Framework**: Flutter (Dart SDK >=3.10.1)

## Tech Stack
- **Languages**: Dart, Kotlin (Android), Swift (iOS/macOS).
- **State Management**: `provider`.
- **Storage**: `shared_preferences`.
- **Audio**: `audioplayers`.
- **Desktop Utils**: `window_manager`.
- **Tools**: `flutter_launcher_icons`.

## User Preferences & Memories
The following preferences have been observed and should be strictly followed:

- **Language**: Always respond in Chinese (总是用中文回答).
- **TypeScript**: Always use `import type` for type imports (typescript 通过import type 导入类型).
- **Git Workflow**: Commit changes before starting major features or refactoring (在修改重大功能之前先保存git).

## Development Conventions
- **Assets**:
  - Sounds located in `assets/sounds/`.
  - App icons generated from `logo.png` using `flutter_launcher_icons`.
- **Build**:
  - Run `flutter pub get` after pulling changes.
  - Run `dart run flutter_launcher_icons` to update icons manifest.
- **Code Style**:
  - Follow Flutter lints (`flutter_lints`).
