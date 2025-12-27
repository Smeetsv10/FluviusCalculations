import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class EnergyDataPoint {
  final DateTime datetime;
  final double remaining; // Energy required (net - solar)

  EnergyDataPoint({required this.datetime, required this.remaining});
}

class GridData extends ChangeNotifier {
  String file_path = '';
  String file_name = '';
  bool flag_EV = true;
  bool flag_PV = true;
  int EAN_ID = -1;
  late DateTime start_date; // iso format
  late DateTime end_date; // iso format
  PlatformFile? selectedFile; // Store the selected file
  Uint8List? csvFileBytes; // Store CSV file bytes

  bool isLoading = false;
  String base64Image = '';
  DateTime? max_end_date = null;
  DateTime? min_start_date = null;

  // Processed data for simulation
  List<EnergyDataPoint> processedData = [];

  GridData() {
    start_date = getRoundedDateTime(DateTime.now()).subtract(Duration(days: 7));
    end_date = getRoundedDateTime(DateTime.now());
  }

  // Getter for SOC
  String get formattedStartDate =>
      DateFormat('dd-MM-yyyy HH:mm').format(start_date);

  String get formattedEndDate =>
      DateFormat('dd-MM-yyyy HH:mm').format(end_date);

  DateTime getRoundedDateTime(DateTime now) {
    // Round to nearest 15 minutes
    int minute = now.minute;
    int roundedMinute = ((minute / 15).round() * 15) % 60;
    int hour = now.hour + ((minute / 15).round() * 15 ~/ 60);

    // Handle hour overflow (e.g. 23:59 rounds to 00:00 next day)
    if (hour >= 24) {
      now = now.add(const Duration(days: 1));
      hour = 0;
    }

    final rounded = DateTime(now.year, now.month, now.day, hour, roundedMinute);

    return rounded;
  }

  String get csvDataBase64 =>
      csvFileBytes != null ? base64Encode(csvFileBytes!) : '';

  Future<bool> pickFiles() async {
    try {
      isLoading = true;
      notifyListeners();

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

        isLoading = false;
        notifyListeners();

        return true;
      } else {
        print('🔍 No file selected');
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error picking file: $e');
      isLoading = false;
      notifyListeners();
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
    DateTime? newStartDate,
    DateTime? newEndDate,
    Uint8List? newCsvFileBytes,
    DateTime? newMinStartDate,
    DateTime? newMaxEndDate,
    String? newBase64Image,
    List<EnergyDataPoint>? newProcessedData,
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
    if (newMinStartDate != null) {
      min_start_date = newMinStartDate;
    }
    if (newMaxEndDate != null) {
      max_end_date = newMaxEndDate;
    }
    if (newCsvFileBytes != null) {
      csvFileBytes = newCsvFileBytes;
    }
    if (newBase64Image != null) {
      base64Image = newBase64Image;
    }
    if (newProcessedData != null) {
      processedData = newProcessedData;
    }
    notifyListeners();
  }

  // Simple CSV parser for simulation (you may want to enhance this)
  void parseCSVData() {
    if (csvFileBytes == null) return;

    try {
      final csvContent = String.fromCharCodes(csvFileBytes!);
      final lines = csvContent.split('\n');

      processedData.clear();

      // Skip header if present
      int startLine =
          lines.isNotEmpty && lines[0].toLowerCase().contains('datetime')
          ? 1
          : 0;

      for (int i = startLine; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length < 2) continue;

        try {
          // Assuming CSV format: datetime, remaining_energy
          // You may need to adjust this based on your actual CSV format
          final dateStr = parts[0].trim();
          final remainingStr = parts[1].trim();

          final datetime = DateTime.parse(dateStr);
          final remaining = double.parse(remainingStr);

          processedData.add(
            EnergyDataPoint(datetime: datetime, remaining: remaining),
          );
        } catch (e) {
          print('Error parsing line $i: $e');
          continue;
        }
      }

      print('Parsed ${processedData.length} data points from CSV');
      notifyListeners();
    } catch (e) {
      print('Error parsing CSV: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'file_path': file_path,
      'flag_EV': flag_EV,
      'flag_PV': flag_PV,
      'EAN_ID': EAN_ID,
      'start_date': formattedStartDate,
      'end_date': formattedEndDate,
      'csv_data': csvDataBase64,
    };
  }
}
