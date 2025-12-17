class FocusSession {
  final DateTime startTime;
  final int durationMinutes;
  final String type; // 'focus' (we only care about focus for now usually)

  FocusSession({
    required this.startTime,
    required this.durationMinutes,
    this.type = 'focus',
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'type': type,
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    startTime: DateTime.parse(json['startTime'] as String),
    durationMinutes: json['durationMinutes'] as int,
    type: json['type'] as String,
  );
}
