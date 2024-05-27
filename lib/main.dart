import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification App',
      home: NotificationScreen(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _messageController = TextEditingController();
  int _interval = 1;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _scheduleNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('message', _messageController.text);
    await prefs.setInt('interval', _interval);

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id', 'your_channel_name', channelDescription: 'your_channel_description',
        importance: Importance.max, priority: Priority.high, showWhen: false);

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics);

    final DateTime scheduledNotificationDateTime = DateTime.now().add(Duration(minutes: _interval));

    await flutterLocalNotificationsPlugin.schedule(
        0,
        'Reminder',
        _messageController.text,
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        androidAllowWhileIdle: true);

    final Duration notificationInterval = Duration(minutes: _interval);

    while (true) {
      await Future.delayed(notificationInterval);
      final DateTime now = DateTime.now();

      await flutterLocalNotificationsPlugin.schedule(
          0,
          'Reminder',
          _messageController.text,
          now.add(notificationInterval),
          platformChannelSpecifics,
          androidAllowWhileIdle: true);
    }
  }

  Future<void> _stopNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('message');
    await prefs.remove('interval');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Enter your message'),
            ),
            DropdownButton<int>(
              value: _interval,
              items: [1, 2, 5, 10, 15, 30, 60].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value minutes'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _interval = newValue!;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _scheduleNotification,
                  child: const Text("Set Notification"),
                ),
                ElevatedButton(
                  onPressed: _stopNotifications,
                  child: const Text("Stop Notifications"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
