# Project Context: Flow Workspace

## Project Overview
**Rhei** is a cross-platform Pomodoro timer application built with Flutter. It focuses on a modern, high-performance user experience featuring a Glassmorphism UI design.

**Key Features:**
- **Pomodoro Timer**: Core focus/break timer functionality.
- **Layout Modes**: "Default" and "Gallery" layouts for different visual preferences.
- **UI Customization**: Adjustable UI opacity, font selection, and theme modes (Light/Dark/System).
- **Sound System**: 
  - Custom alarm and ambient sound support (`audioplayers`)
  - **Modern Sound Picker**: Bottom sheet modal with 4-column grid layout
  - **Sound Preview**: Auto-play on selection (5s for ambient, full for alarms)
  - **Custom Sounds**: Add/delete custom audio files for both alarm and ambient sounds
  - **Sound Management**: Hide/show built-in sounds, scrolling text for long filenames
  - **Performance Optimized**: Separate preview player, auto-cleanup on dialog close
- **Notifications**: System notifications for timer events (`flutter_local_notifications`).
- **Android Widget**: 
  - Real-time timer display with circular progress indicator
  - Smart pause control (only available during Focus mode, hidden during breaks)
  - Performance-optimized with state caching to prevent UI flickering
  - Syncs colors and background settings from main app
- **Background Image Carousel**:
  - Multi-image slideshow (up to 10 images)
  - Configurable carousel interval (5-60s, default 6s)
  - Smooth crossfade transitions (800ms)
  - Smart image compression (auto-resize to 1920px max, JPEG 85%)
  - Portrait/landscape optimization
  - Modern bottom-sheet image manager
  - Background type selection: Default gradient, Solid color, or Image carousel
- **Window Control**: "Always on Top" and other window management features (`window_manager`).
  - Desktop window size: 405x720 (9:16 portrait ratio, optimized for modern photos)
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
- **Image Processing**: `image` (compression and optimization).
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
