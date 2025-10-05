import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String uid = Uuid().v4();

  // Write to shared preferences

  // Read from shared preferences

  Map<String, dynamic> toJson(House house) {
    return {'uid': uid, 'house': house.toJson()};
  }
}
