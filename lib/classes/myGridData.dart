import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

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
  // Initial default values for resetting
  static const String _INITIAL_FILE_PATH = '';
  static const String _INITIAL_FILE_NAME = '';
  static const bool _INITIAL_FLAG_EV = true;
  static const bool _INITIAL_FLAG_PV = true;
  static const int _INITIAL_EAN_ID = -1;
  static const bool _INITIAL_IS_LOADING = false;

  String file_path = _INITIAL_FILE_PATH; // Filepath to the Fluvius csv file
  String file_name = _INITIAL_FILE_NAME; // Filename of the selected file
  bool flag_EV = _INITIAL_FLAG_EV;
  bool flag_PV = _INITIAL_FLAG_PV;
  int EAN_ID = _INITIAL_EAN_ID;
  late DateTime start_date; // start date for the selected data (UTC formatted)
  late DateTime end_date; // end date for the selected data (UTC formatted)
  PlatformFile? selectedFile; // Store the selected file
  Uint8List? csvFileBytes; // Store CSV file bytes

  bool isLoading = _INITIAL_IS_LOADING;
  DateTime? max_end_date = null; // Latest available date in CSV
  DateTime? min_start_date = null; // Earliest available date in CSV

  // Processed data for simulation
  List<EnergyDataPoint> processedData = [];
  List<EnergyDataPoint> rawData = [];
  Duration dt = Duration(minutes: 15);

  GridData() {
    initializeParameters();
  }

  void initializeParameters() {
    file_path = _INITIAL_FILE_PATH;
    file_name = _INITIAL_FILE_NAME;
    flag_EV = _INITIAL_FLAG_EV;
    flag_PV = _INITIAL_FLAG_PV;
    EAN_ID = _INITIAL_EAN_ID;
    isLoading = _INITIAL_IS_LOADING;
    selectedFile = null;
    csvFileBytes = null;
    max_end_date = null;
    min_start_date = null;
    processedData = [];
    rawData = [];
    dt = Duration(minutes: 15);
    start_date = getRoundedDateTime(DateTime.now()).subtract(Duration(days: 7));
    end_date = getRoundedDateTime(DateTime.now());
    notifyListeners();
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

  void parseCSVData_old() {
    if (csvFileBytes == null) return;
    try {
      final csvContent = String.fromCharCodes(csvFileBytes!);
      final lines = csvContent.split('\n');

      rawData.clear();

      // Skip header if present
      int startLine = lines.isNotEmpty && lines[0].toLowerCase().contains('ean')
          ? 1
          : 0;

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

  void parseCSVData() {
    if (csvFileBytes == null) return;

    try {
      final csvContent = String.fromCharCodes(csvFileBytes!);
      final lines = csvContent.split('\n');

      // Remove header
      if (lines.isNotEmpty) {
        lines.removeAt(0);
      }

      final brussels = tz.getLocation('Europe/Brussels');
      const expectedInterval = Duration(minutes: 15);

      DateTime _parseStartUtc(List<String> cols) {
        final d = cols[0].split('-');
        final t = cols[1].split(':');

        return tz.TZDateTime(
          brussels,
          int.parse(d[2]),
          int.parse(d[1]),
          int.parse(d[0]),
          int.parse(t[0]),
          int.parse(t[1]),
          int.parse(t[2]),
        ).toUtc();
      }

      DateTime _parseEndUtc(List<String> cols) {
        final d = cols[2].split('-');
        final t = cols[3].split(':');

        return tz.TZDateTime(
          brussels,
          int.parse(d[2]),
          int.parse(d[1]),
          int.parse(d[0]),
          int.parse(t[0]),
          int.parse(t[1]),
          int.parse(t[2]),
        ).toUtc();
      }

      // Temporary map to merge Afname + Injectie per UTC timestamp
      final Map<DateTime, Map<String, double>> tempMap = {};

      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        final cols = line.split(';');

        final startUtc = _parseStartUtc(cols);
        final register = cols[7].trim().toLowerCase();
        final volumeStr = cols[8].trim();

        double volume = 0.0;
        if (volumeStr.isNotEmpty) {
          volume = double.tryParse(volumeStr.replaceAll(',', '.')) ?? 0.0;
        }

        tempMap.putIfAbsent(startUtc, () => {'afname': 0.0, 'injectie': 0.0});

        if (register.contains('afname')) {
          tempMap[startUtc]!['afname'] = volume;
        } else if (register.contains('injectie')) {
          tempMap[startUtc]!['injectie'] = volume;
        }
      }

      // Convert to EnergyDataPoint list (UTC!)
      tempMap.forEach((utcDateTime, values) {
        rawData.add(
          EnergyDataPoint(
            datetime: utcDateTime,
            volume_afname_kwh: values['afname'] ?? 0.0,
            volume_injectie_kwh: values['injectie'] ?? 0.0,
          ),
        );
      });

      rawData.sort((a, b) => a.datetime.compareTo(b.datetime));

      // Set start and end dates
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
