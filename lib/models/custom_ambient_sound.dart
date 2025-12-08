class CustomAmbientSound {
  final String id;
  final String name;
  final String filePath;

  CustomAmbientSound({
    required this.id,
    required this.name,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
  };

  factory CustomAmbientSound.fromJson(Map<String, dynamic> json) => CustomAmbientSound(
    id: json['id'] as String,
    name: json['name'] as String,
    filePath: json['filePath'] as String,
  );
}
