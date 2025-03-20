import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:accelerometer/accelerometer.dart';
import 'package:accelerometer/location.dart';

class DisplayScreen extends StatefulWidget {
  @override
  _DisplayScreenState createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  late LocationCalculator _locationCalculator;
  late AccelerometerCalculator _accelerometerCalculator;

  double latitude = 0.0;
  double longitude = 0.0;
  double x = 0.0, y = 0.0, z = 0.0;
  bool isRunning = false;
  Timer? _recordingTimer;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _accelerometerSubscription;

  // CSV header with a timestamp column.
  List<List<dynamic>> _csvData = [
    ['Timestamp', 'Latitude', 'Longitude', 'X', 'Y', 'Z']
  ];

  @override
  void initState() {
    super.initState();
    _locationCalculator = LocationCalculator();
    _accelerometerCalculator = AccelerometerCalculator();
  }

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  void _start() {
    if (isRunning) return;
    setState(() {
      isRunning = true;
    });

    // Subscribe to location updates to update latest values (without recording).
    _locationSubscription = _locationCalculator.locationStream.listen((position) {
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    });

    // Subscribe to accelerometer updates to update latest values (without recording).
    _accelerometerSubscription = _accelerometerCalculator.accelerometerStream.listen((event) {
      setState(() {
        x = event.x;
        y = event.y;
        z = event.z;
      });
    });

    // Start a periodic timer that records the current sensor values every 200ms (5 times per second).
    _recordingTimer = Timer.periodic(Duration(milliseconds: 1000), (Timer timer) {
      _addDataToCsv();
    });
  }

  void _stop() {
    if (!isRunning) return;
    setState(() {
      isRunning = false;
    });

    _locationSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _recordingTimer?.cancel();
    _locationSubscription = null;
    _accelerometerSubscription = null;
    _recordingTimer = null;

    _saveCsv();
  }

  // Record a row with the current sensor values and timestamp.
  void _addDataToCsv() {
    String timestamp = DateTime.now().toIso8601String();
    _csvData.add([timestamp, latitude, longitude, x, y, z]);
  }

  Future<void> _saveCsv() async {
    try {
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission not granted.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to get storage directory.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final path = directory.path;
      // Create a unique file name using a timestamp.
      final fileTimestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('$path/sensor_data_$fileTimestamp.csv');

      String csv = const ListToCsvConverter().convert(_csvData);
      await file.writeAsString(csv);

      // Reset CSV data for the next session (include header row).
      _csvData = [
        ['Timestamp', 'Latitude', 'Longitude', 'X', 'Y', 'Z']
      ];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV file saved to ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save CSV file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationCalculator.dispose();
    _accelerometerCalculator.dispose();
    _locationSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png'),
        ),
        title: const Text(
          "Road Pavement App",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.teal, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoCard(
                  title: "Location",
                  content: [
                    "Latitude: $latitude",
                    "Longitude: $longitude",
                  ],
                  icon: Icons.location_on,
                  iconColor: Colors.green,
                ),
                const SizedBox(height: 20),
                _buildInfoCard(
                  title: "Accelerometer",
                  content: [
                    "X: ${x.toStringAsFixed(2)}",
                    "Y: ${y.toStringAsFixed(2)}",
                    "Z: ${z.toStringAsFixed(2)}",
                  ],
                  icon: Icons.speed,
                  iconColor: Colors.orange,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isRunning ? _stop : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRunning ? Colors.red : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text(
                    isRunning ? "Stop" : "Start",
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<String> content,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 10,
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 40),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 10),
                  for (var line in content)
                    Text(line,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
