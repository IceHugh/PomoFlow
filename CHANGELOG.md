## [0.1.0] - 2025-12-06

### Added
- **Custom Backgrounds**: Users can now select solid colors or local images as the timer background.
- **Image Caching**: Selected background images are cached internally to prevent issues if source files are deleted.
- **Settings UI**: Enhanced "Appearance" section in Settings for background customization.
- **Dependencies**: Added `flutter_colorpicker`, `file_picker`, and `path_provider`.

### Changed
- Updated `README.md` and `GEMINI.md` to reflect new features.
- Optimized glassmorphism effect handling for image backgrounds (disabled blur for better visibility).

### Fixed
- Fixed issue where background images would not persist after app restart on macOS due to sandbox restrictions.
