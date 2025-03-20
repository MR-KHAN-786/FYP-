import 'dart:async';
import 'package:accelerometer/accelerometer.dart';
import 'package:accelerometer/location.dart';
import 'package:flutter/material.dart';

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
  StreamSubscription? _locationSubscription;
  StreamSubscription? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _locationCalculator = LocationCalculator();
    _accelerometerCalculator = AccelerometerCalculator();
  }

 void _start() {
  if (isRunning) return; // Prevent starting again if already running

  setState(() {
    isRunning = true;
  });

  // Initialize location subscription
  _locationSubscription =
      _locationCalculator.locationStream.listen((position) {
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
    });
  });

  // Initialize accelerometer subscription
  _accelerometerSubscription =
      _accelerometerCalculator.accelerometerStream.listen((event) {
    setState(() {
      x = event.x;
      y = event.y;
      z = event.z;
    });
  });
}

void _stop() {
  if (!isRunning) return; // Prevent stopping if already stopped

  setState(() {
    isRunning = false;
  });

  // Cancel subscriptions
  _locationSubscription?.cancel();
  _accelerometerSubscription?.cancel();
  _locationSubscription = null;
  _accelerometerSubscription = null;

  // Do not reset displayed values
}

  @override
  void dispose() {
    _locationCalculator.dispose();
    _accelerometerCalculator.dispose();
    _locationSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png'), // Replace with your logo asset path
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
                // Location Card
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
                // Accelerometer Card
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
                // Start/Stop Button
                ElevatedButton(
                  onPressed: isRunning ? _stop : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRunning ? Colors.red : Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
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
            Icon(
              icon,
              color: iconColor,
              size: 40,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var line in content)
                    Text(
                      line,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
