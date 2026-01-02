import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class EnergyDataPoint {
  final DateTime datetime; // Timestamp of the data point
  final double volume_afname_kwh; // Energy taken from net (kWh)
  final double volume_injectie_kwh; // Energy injected to net (kWh)

  EnergyDataPoint({
    required this.datetime,
    required this.volume_afname_kwh,
    required this.volume_injectie_kwh,
  });
}

class GridData extends ChangeNotifier {
  String file_path = ''; // Filepath to the Fluvius csv file
  String file_name = ''; // Filename of the selected file
  bool flag_EV = true;
  bool flag_PV = true;
  int EAN_ID = -1;
  late DateTime start_date; // start date for the selected data (UTC formatted)
  late DateTime end_date; // end date for the selected data (UTC formatted)
  PlatformFile? selectedFile; // Store the selected file
  Uint8List? csvFileBytes; // Store CSV file bytes

  bool isLoading = false;
  DateTime? max_end_date = null; // Latest available date in CSV
  DateTime? min_start_date = null; // Earliest available date in CSV

  // Processed data for simulation
  List<EnergyDataPoint> processedData = [];
  List<EnergyDataPoint> rawData = [];

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

        parseCSVData();
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
    if (newProcessedData != null) {
      processedData = newProcessedData;
    }
    notifyListeners();
  }

  void parseCSVData() {
    if (csvFileBytes == null) return;
    try {
      final csvContent = String.fromCharCodes(csvFileBytes!);
      final lines = csvContent.split('\n');

      rawData.clear();

      // Skip header if present
      int startLine =
          lines.isNotEmpty && lines[0].toLowerCase().contains('ean_id') ? 1 : 0;

      for (int i = startLine; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length < 2) continue;

        try {
          if (EAN_ID == -1) {
            EAN_ID = int.parse(parts[0].trim());
          }
          final dateStr = DateTime.parse(parts[2].trim());
          final volAfname = double.parse(parts[3].trim());
          final volInjectie = double.parse(parts[4].trim());

          rawData.add(
            EnergyDataPoint(
              datetime: dateStr,
              volume_afname_kwh: volAfname,
              volume_injectie_kwh: volInjectie,
            ),
          );
        } catch (e) {
          print('Error parsing line $i: $e');
          continue;
        }
      }
      max_end_date ??= rawData.last.datetime;
      min_start_date ??= rawData.first.datetime;
      if (min_start_date != null) {
        start_date = min_start_date!;
      }
      if (max_end_date != null) {
        end_date = max_end_date!;
      }
      notifyListeners();
    } catch (e) {
      print('Error parsing CSV: $e');
    }
  }

  void processCSVData() {
    // Apply date mask
    processedData = rawData
        .where(
          (dataPoint) =>
              dataPoint.datetime.isAfter(
                start_date.subtract(const Duration(minutes: 1)),
              ) &&
              dataPoint.datetime.isBefore(
                end_date.add(const Duration(minutes: 1)),
              ),
        )
        .toList();
    notifyListeners();
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
