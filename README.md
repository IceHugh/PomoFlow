# PomoFlow 🍅

A modern, high-performance Pomodoro timer application built with Flutter, featuring a stunning Glassmorphism UI design.

![PomoFlow Banner](https://via.placeholder.com/1280x640.png?text=PomoFlow+Glassmorphism+UI)
*(Screenshots placeholders - to be updated)*

## ✨ Key Features

- **🎨 Modern Glassmorphism Design**: A sleek, frosted-glass aesthetic offering a premium user experience.
- **🖼️ Custom Backgrounds**: Personalize your timer with solid colors or your own images.
- **⏱️ Customizable Timer**: Flexible focus and break durations to suit your workflow.
- **🔊 Immersive Soundscapes**: Custom ambient sounds and pleasant alarm tones powered by `audioplayers`.
- **🔔 Smart Notifications**: Native system notifications keep you informed without being intrusive (`flutter_local_notifications`).
- **🪟 Advanced Window Control**: "Always on Top" mode ensures your timer is always visible when you need it (`window_manager`).
- **💻 Cross-Platform**: Optimized for macOS, Windows, Android, and iOS.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK >=3.10.1)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences) & [path_provider](https://pub.dev/packages/path_provider)
- **Audio**: [audioplayers](https://pub.dev/packages/audioplayers)
- **Desktop Integration**: [window_manager](https://pub.dev/packages/window_manager)
- **UI Extensions**: [flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker), [file_picker](https://pub.dev/packages/file_picker)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured.
- Compatible IDE (VS Code, Android Studio, etc.).

### Installation

1.  **Clone the repository:**
    ```bash
    git clone git@github.com:IceHugh/PomoFlow.git
    cd pomoflow
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    # Run on macOS
    flutter run -d macos

    # Run on Android (ensure emulator is running or device connected)
    flutter run -d android
    ```

## 🧑‍💻 Development

### Generating App Icons
If you update `logo.png`, regenerate the platform-specific icons:
```bash
dart run flutter_launcher_icons
```

### Code Style
This project follows strictly configured lints. Check for issues:
```bash
flutter analyze
```


## ⚠️ Troubleshooting

### macOS: "App is damaged" or "Unverified Developer"
If you see a warning that "PomoFlow cannot be opened because Apple cannot check it for malicious software":

1.  Open **System Settings** > **Privacy & Security**.
2.  Scroll down to the security section and click **"Open Anyway"** for PomoFlow.

Alternatively, running this command in Terminal will verify the app:
```bash
xattr -d com.apple.quarantine /path/to/PomoFlow.app
```

## 📄 License

[MIT License](LICENSE) (Placeholder)

---
*Built with ❤️ using Flutter*
