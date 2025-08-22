import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CronolocoApp());
}

class CronolocoApp extends StatelessWidget {
  const CronolocoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronoloco',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ActivityListScreen(),
    );
  }
}

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

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  List<Activity> activities = [];
  final String storageKey = 'activities';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activitiesJson = prefs.getString(storageKey);
    if (activitiesJson != null) {
      final List<dynamic> decodedActivities = jsonDecode(activitiesJson);
      setState(() {
        activities = decodedActivities
            .map((item) => Activity.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedActivities =
        jsonEncode(activities.map((a) => a.toJson()).toList());
    await prefs.setString(storageKey, encodedActivities);
  }

  void _addActivity() {
    showDialog(
      context: context,
      builder: (context) {
        String newActivityName = '';
        return AlertDialog(
          title: const Text('New Activity'),
          content: TextField(
            onChanged: (value) => newActivityName = value,
            decoration: const InputDecoration(labelText: 'Activity Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newActivityName.isNotEmpty) {
                  setState(() {
                    activities.add(Activity(
                      id: DateTime.now().toString(),
                      name: newActivityName,
                    ));
                    _saveActivities();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _toggleTimer(Activity activity) {
    setState(() {
      activity.isRunning = !activity.isRunning;
      if (activity.isRunning) {
        activity.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            activity.todayDuration += const Duration(seconds: 1);
            _saveActivities();
          });
        });
      } else {
        activity.timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronoloco'),
        actions: [
          TextButton(
            onPressed: () {}, // Export functionality to be added
            child: const Text('Export'),
          ),
          TextButton(
            onPressed: () {}, // Import functionality to be added
            child: const Text('Import'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = activities.removeAt(oldIndex);
                  activities.insert(newIndex, item);
                  _saveActivities();
                });
              },
              children: activities.map((activity) {
                String timeStr = _formatDuration(activity.todayDuration);
                return Card(
                  key: Key(activity.id),
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle),
                    title: Text(activity.name),
                    subtitle: Text(timeStr),
                    trailing: IconButton(
                      icon: Icon(
                        activity.isRunning ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: () => _toggleTimer(activity),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _addActivity,
              child: const Text('Add Activity'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    for (var activity in activities) {
      activity.timer?.cancel();
    }
    super.dispose();
  }
}
