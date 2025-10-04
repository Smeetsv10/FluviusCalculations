import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class GridData extends ChangeNotifier {
  String file_path = '';
  String file_name = '';
  bool flag_EV = true;
  bool flag_PV = true;
  int EAN_ID = -1;
  late String start_date;
  late String end_date;
  PlatformFile? selectedFile; // Store the selected file
  Uint8List? csvFileBytes; // Store CSV file bytes

  GridData() {
    start_date = DateFormat(
      'dd-MM-yyyy',
    ).format(DateTime.now().subtract(Duration(days: 7)));
    end_date = DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  // Getter for SOC
  DateTime stringToDateTime(String dateStr) {
    return DateFormat("dd-MM-yyyy").parse(dateStr);
  }

  String get csvDataBase64 => base64Encode(csvFileBytes!);

  Future<bool> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        selectedFile = file;
        csvFileBytes = file.bytes;

        if (kIsWeb) {
          file_path = file.name;
        } else {
          file_path = file.path ?? file.name;
        }

        // Optional debug preview
        if (csvFileBytes != null) {
          try {
            final csvContent = String.fromCharCodes(csvFileBytes!);
            print(
              '🔍 CSV preview: ${csvContent.substring(0, csvContent.length.clamp(0, 200))}',
            );
          } catch (e) {
            print('⚠️ Could not preview CSV: $e');
          }
        }

        return true;
      } else {
        print('🔍 No file selected');
        return false;
      }
    } catch (e) {
      print('❌ Error picking file: $e');
      // Propagate the error
      throw Exception('Failed to select file: $e');
    }
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
      'flag_EV': flag_EV,
      'flag_PV': flag_PV,
      'EAN_ID': EAN_ID,
      'start_date': start_date,
      'end_date': end_date,
      'csv_data': csvDataBase64,
    };
  }
}
