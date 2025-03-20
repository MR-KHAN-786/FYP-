import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class AccelerometerCalculator {
  final _accelerometerController = StreamController<AccelerometerEvent>.broadcast();

  Stream<AccelerometerEvent> get accelerometerStream =>
      _accelerometerController.stream;

  AccelerometerCalculator() {
    _initializeAccelerometer();
  }

  void _initializeAccelerometer() {
    // Listen to native accelerometer events and forward to the broadcast stream
    accelerometerEvents.listen((event) {
      if (!_accelerometerController.isClosed) {
        _accelerometerController.add(event);
      }
    });
  }

  void dispose() {
    _accelerometerController.close();
  }
}
