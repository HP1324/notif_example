import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
  NotificationService.initNotifications();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Notifications',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TaskSchedulerScreen(),
    );
  }
}

class Task {
  final int id;
  final String title;
  final DateTime dueDate;
  final bool isNotifyEnabled;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.isNotifyEnabled,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dueDate': dueDate.toIso8601String(),
    'isNotifyEnabled': isNotifyEnabled,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    dueDate: DateTime.parse(json['dueDate']),
    isNotifyEnabled: json['isNotifyEnabled'],
  );
}

class NotificationService {
  static final _notif = AwesomeNotifications();

  static Future<void> initNotifications() async {
    _notif.initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'task_notif',
          channelName: 'Task Notifications',
          channelDescription: 'Notifications for tasks',
          importance: NotificationImportance.Max,
          playSound: true,
          enableLights: true,
          channelShowBadge: true,
        ),
      ],
    );

    await _notif.isNotificationAllowed().then((allowed) async {
      if (!allowed) {
        await _notif.requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> createTaskNotification(Task task) async {
    if (task.isNotifyEnabled) {
      String taskPayload = jsonEncode(task.toJson());
      await _notif.createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'task_notif',
          title: 'Task Reminder',
          body: task.title,
          payload: {'task': taskPayload},
        ),
        schedule: NotificationCalendar.fromDate(
          date: task.dueDate,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    }
  }
}

class TaskSchedulerScreen extends StatefulWidget {
  const TaskSchedulerScreen({Key? key}) : super(key: key);

  @override
  State<TaskSchedulerScreen> createState() => _TaskSchedulerScreenState();
}

class _TaskSchedulerScreenState extends State<TaskSchedulerScreen> {
  final TextEditingController _taskTitleController = TextEditingController();
  DateTime? _selectedDateTime;

  Future<void> _pickDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _scheduleTask() {
    if (_taskTitleController.text.isNotEmpty && _selectedDateTime != null) {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch,
        title: _taskTitleController.text,
        dueDate: _selectedDateTime!,
        isNotifyEnabled: true,
      );
      NotificationService.createTaskNotification(task);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification scheduled for "${task.title}"')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Scheduler')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _pickDateTime(context),
              child: const Text('Pick Due Date & Time'),
            ),
            const SizedBox(height: 8),
            if (_selectedDateTime != null)
              Text('Selected: ${_selectedDateTime!.toLocal()}'),
            const Spacer(),
            ElevatedButton(
              onPressed: _scheduleTask,
              child: const Text('Schedule Task'),
            ),
          ],
        ),
      ),
    );
  }
}
