import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:uuid/uuid.dart';

class User {
  final String uid = Uuid().v4();

  User() {
    initializeParameters();
  }

  void initializeParameters() {
    // User class primarily stores uid which is immutable
    // No additional parameters to reset
  }

  // Write to shared preferences

  // Read from shared preferences

  Map<String, dynamic> toJson(House house) {
    return {'uid': uid, 'house': house.toJson()};
  }
}
