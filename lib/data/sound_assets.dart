
class SoundAsset {
  final String id;
  final String name;
  final String path;
  final SoundType type;
  final String? sourceUrl; // For future downloading

  const SoundAsset({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.sourceUrl,
  });
}

enum SoundType {
  alarm,
  ambient,
}

class SoundLibrary {
  static const List<SoundAsset> alarms = [
    SoundAsset(
      id: 'bell',
      name: 'Bell',
      path: 'assets/sounds/alarms/bell.mp3',
      type: SoundType.alarm,
      sourceUrl: 'https://github.com/londonappbrewery/Xylophone-Flutter/raw/master/assets/note1.wav', // Placeholder
    ),
    SoundAsset(
      id: 'digital',
      name: 'Digital',
      path: 'assets/sounds/alarms/digital.mp3',
      type: SoundType.alarm,
    ),
  ];

  static const List<SoundAsset> ambient = [
    SoundAsset(
      id: 'rain',
      name: 'Rain',
      path: 'assets/sounds/ambient/rain.mp3',
      type: SoundType.ambient,
    ),
    SoundAsset(
      id: 'forest',
      name: 'Forest',
      path: 'assets/sounds/ambient/forest.mp3',
      type: SoundType.ambient,
    ),
  ];
  
  static const List<SoundAsset> all = [...alarms, ...ambient];
}
