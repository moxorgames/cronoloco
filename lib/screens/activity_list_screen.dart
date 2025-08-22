import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../models/activity.dart';
import '../utils/time_formatter.dart';

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

  void _toggleTimer(Activity selectedActivity) {
    setState(() {
      // Stop any running activity first
      for (var activity in activities) {
        if (activity.id != selectedActivity.id && activity.isRunning) {
          activity.isRunning = false;
          activity.timer?.cancel();
        }
      }

      // Toggle the selected activity
      selectedActivity.isRunning = !selectedActivity.isRunning;
      if (selectedActivity.isRunning) {
        selectedActivity.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            selectedActivity.todayDuration += const Duration(seconds: 1);
            _saveActivities();
          });
        });
      } else {
        selectedActivity.timer?.cancel();
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
                String timeStr = TimeFormatter.formatDuration(activity.todayDuration);
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

  @override
  void dispose() {
    for (var activity in activities) {
      activity.timer?.cancel();
    }
    super.dispose();
  }
}