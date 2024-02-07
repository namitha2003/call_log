import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class CustomCallLog {
  final String callerName;
  final String phoneNumber;
  final String callDuration;
  final DateTime? timestamp;

  CustomCallLog({
    required this.callerName,
    required this.phoneNumber,
    required this.callDuration,
    required this.timestamp,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Log',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Call Log '),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CustomCallLog> callLogs = [];
  List<CustomCallLog> filteredCallLogs = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Add default entries
    callLogs.addAll([
      CustomCallLog(
        callerName: 'Namitha',
        phoneNumber: '6305251883',
        callDuration: '12 minutes',
        timestamp: DateTime.now(),
      ),
      CustomCallLog(
        callerName: 'Manush',
        phoneNumber: '9876543210',
        callDuration: '8 minutes',
        timestamp: DateTime.now(),
      ),
      CustomCallLog(
        callerName: 'Ramya',
        phoneNumber: '1234567890',
        callDuration: '20 minutes',
        timestamp: DateTime.now(),
      ),
      CustomCallLog(
        callerName: 'Daddy',
        phoneNumber: '8876543560',
        callDuration: '30 minutes',
        timestamp: DateTime.now(),
      ),
      // Add more call logs as needed
    ]);

    _retrieveCallLogs();
  }

  Future<void> _retrieveCallLogs() async {
    try {
      // Check and request permissions only if not running on the web
      if (!kIsWeb) {
        if (Platform.isAndroid || Platform.isIOS) {
          var status = await Permission.contacts.status;
          if (!status.isGranted) {
            // Request permission and handle denial
            var result = await Permission.contacts.request();
            if (result.isDenied) {
              // User denied the permission, handle it accordingly
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Permission denied. Please grant access in settings.'),
                ),
              );
              return;
            }
          }
        }
      }

      // Retrieve call log entries only if callLogs is empty
      if (callLogs.isEmpty) {
        Iterable<CallLogEntry> entries = await CallLog.query();

        setState(() {
          callLogs = entries.map((entry) {
            return CustomCallLog(
              callerName: entry.name ?? 'Unknown Caller',
              phoneNumber: entry.number ?? 'Unknown Number',
              callDuration: entry.duration.toString(),
              timestamp:
                  DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0),
            );
          }).toList();

          filteredCallLogs = List.from(callLogs);
        });
      }
    } catch (e) {
      print('Error retrieving call logs: $e');
      // Handle the error gracefully (show a message to the user, log it, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error retrieving call logs. Please try again.'),
        ),
      );
    }
  }

  void _sortCallLogs() {
    setState(() {
      callLogs.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
      filteredCallLogs = List.from(callLogs);
    });
  }

  void _searchCallLogs(String query) {
    setState(() {
      filteredCallLogs = callLogs
          .where((log) =>
              log.callerName.toLowerCase().contains(query.toLowerCase()) ||
              log.phoneNumber.contains(query))
          .toList();
    });
  }

  void _addNewCallLog(
      String newCallerName, String newPhoneNumber, String newCallDuration) {
    CustomCallLog newCallLog = CustomCallLog(
      callerName: newCallerName,
      phoneNumber: newPhoneNumber,
      callDuration: newCallDuration,
      timestamp: DateTime.now(),
    );

    setState(() {
      callLogs.add(newCallLog);
      filteredCallLogs = List.from(callLogs);
    });
  }

  void _showAddCallLogDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController phoneController = TextEditingController();
        TextEditingController durationController = TextEditingController();

        return AlertDialog(
          title: Text('Add New Call Log'),
          content: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Caller Name',
                  icon: Icon(Icons.person),
                ),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  icon: Icon(Icons.phone),
                ),
              ),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Call Duration',
                  icon: Icon(Icons.timer),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addNewCallLog(
                  nameController.text,
                  phoneController.text,
                  durationController.text,
                );
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(widget.title),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _sortCallLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: _searchCallLogs,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: CallLogList(callLogs: filteredCallLogs),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCallLogDialog();
        },
        tooltip: 'Add New Call Log',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CallLogList extends StatelessWidget {
  final List<CustomCallLog> callLogs;

  CallLogList({required this.callLogs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: callLogs.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4.0,
          margin: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: ListTile(
            title: Text(callLogs[index].callerName),
            subtitle: Text(callLogs[index].phoneNumber),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(callLogs[index].callDuration),
                Text(
                  DateFormat('HH:mm').format(callLogs[index].timestamp!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
