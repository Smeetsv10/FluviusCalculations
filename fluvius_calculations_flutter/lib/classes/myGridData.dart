import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class GridData extends ChangeNotifier {
  String file_path = '';
  String file_name = '';
  bool flag_EV = true;
  bool flag_PV = true;
  int EAN_ID = -1;
  String start_date = '31-12-1999';
  String end_date = '31-12-1999';
  // DataTable df = DataTable(columns: [], rows: []);

  PlatformFile? selectedFile; // Store the selected file
  Uint8List? csvFileBytes; // Store CSV file bytes

  GridData() {
    if (stringToDateTime(start_date).isAfter(stringToDateTime(end_date))) {
      throw ArgumentError('Start date must be before end date');
    }
  }

  // Getter for SOC
  DateTime stringToDateTime(String dateStr) {
    return DateFormat("dd-MM-yyyy").parse(dateStr);
  }

  void updateParameters({
    String? newFilePath,
    String? newFileName,
    bool? newFlagEV,
    bool? newFlagPV,
    int? newEANID,
    String? newStartDate,
    String? newEndDate,
    Uint8List? newCsvFileBytes,
  }) {
    if (newFilePath != null) {
      file_path = newFilePath;
    }
    if (newFileName != null) {
      file_name = newFileName;
    }
    if (newFlagEV != null) {
      flag_EV = newFlagEV;
    }
    if (newFlagPV != null) {
      flag_PV = newFlagPV;
    }
    if (newEANID != null) {
      EAN_ID = newEANID;
    }
    if (newStartDate != null) {
      start_date = newStartDate;
    }
    if (newEndDate != null) {
      end_date = newEndDate;
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'file_path': file_path,
      'file_name': file_name,
      'flag_EV': flag_EV,
      'flag_PV': flag_PV,
      'EAN_ID': EAN_ID,
      'start_date': start_date,
      'end_date': end_date,
    };
  }
}
