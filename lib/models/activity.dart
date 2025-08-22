import 'dart:async';

class Activity {
  String id;
  String name;
  bool isRunning;
  Duration todayDuration;
  Timer? timer;

  Activity({
    required this.id,
    required this.name,
    this.isRunning = false,
    this.todayDuration = const Duration(),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'todayDuration': todayDuration.inSeconds,
      };

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      todayDuration: Duration(seconds: json['todayDuration']),
    );
  }
}