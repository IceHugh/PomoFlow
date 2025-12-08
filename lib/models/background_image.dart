/// Background image data model
class BackgroundImage {
  final String id;
  final String name;
  final String filePath;
  final bool isSelected; // Whether this image participates in carousel

  const BackgroundImage({
    required this.id,
    required this.name,
    required this.filePath,
    this.isSelected = false,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'isSelected': isSelected,
    };
  }

  factory BackgroundImage.fromJson(Map<String, dynamic> json) {
    return BackgroundImage(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  // Copy with method for updates
  BackgroundImage copyWith({
    String? id,
    String? name,
    String? filePath,
    bool? isSelected,
  }) {
    return BackgroundImage(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
