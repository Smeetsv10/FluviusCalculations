import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

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

  String get base64Image {
    if (processedData.isEmpty) return '';

    try {
      // Image dimensions
      const int width = 1000;
      const int height = 600;
      const double padding = 60.0;
      const double graphWidth = width - 2 * padding;
      const double graphHeight = height - 2 * padding;

      // Find min/max values for scaling
      double maxVolAfname = 0;
      double maxVolInjectie = 0;
      for (var p in processedData) {
        if (p.volume_afname_kwh > maxVolAfname)
          maxVolAfname = p.volume_afname_kwh;
        if (p.volume_injectie_kwh > maxVolInjectie)
          maxVolInjectie = p.volume_injectie_kwh;
      }
      double maxVol = maxVolAfname > maxVolInjectie
          ? maxVolAfname
          : maxVolInjectie;
      if (maxVol == 0) maxVol = 1;

      // Create SVG string
      final StringBuffer svg = StringBuffer();
      svg.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      svg.writeln(
        '<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">',
      );

      // Background
      svg.writeln('<rect width="$width" height="$height" fill="white"/>');

      // Title

      svg.writeln(
        '<text x="${width / 2}" y="30" font-size="20" font-weight="bold" text-anchor="middle" fill="black">Energy Data ($formattedStartDate - $formattedEndDate)</text>',
      );

      // Y-axis label
      svg.writeln(
        '<text x="15" y="${height / 2}" font-size="14" text-anchor="middle" transform="rotate(-90, 15, ${height / 2})" fill="black">Energy (kWh)</text>',
      );

      // X-axis label
      svg.writeln(
        '<text x="${width / 2}" y="${height - 5}" font-size="14" text-anchor="middle" fill="black">Datetime (15min)</text>',
      );

      // Draw axes
      svg.writeln(
        '<line x1="$padding" y1="${height - padding}" x2="${width - padding}" y2="${height - padding}" stroke="black" stroke-width="2"/>',
      );
      svg.writeln(
        '<line x1="$padding" y1="$padding" x2="$padding" y2="${height - padding}" stroke="black" stroke-width="2"/>',
      );

      // Y-axis ticks and labels
      for (int i = 0; i <= 5; i++) {
        double yVal = (maxVol / 5) * i;
        double yPos = height - padding - (i / 5) * graphHeight;
        svg.writeln(
          '<line x1="${padding - 5}" y1="$yPos" x2="$padding" y2="$yPos" stroke="black" stroke-width="1"/>',
        );
        svg.writeln(
          '<text x="${padding - 10}" y="${yPos + 5}" font-size="12" text-anchor="end" fill="black">${yVal.toStringAsFixed(2)}</text>',
        );
      }

      // Plot lines
      if (processedData.length > 1) {
        StringBuffer pathAfname = StringBuffer('M ');
        StringBuffer pathInjectie = StringBuffer('M ');

        for (int i = 0; i < processedData.length; i++) {
          final dataPoint = processedData[i];
          final x = padding + (i / (processedData.length - 1)) * graphWidth;
          final yAfname =
              height -
              padding -
              (dataPoint.volume_afname_kwh / maxVol) * graphHeight;
          final yInjectie =
              height -
              padding -
              (dataPoint.volume_injectie_kwh / maxVol) * graphHeight;

          if (i == 0) {
            pathAfname.write('$x $yAfname ');
            pathInjectie.write('$x $yInjectie ');
          } else {
            pathAfname.write('L $x $yAfname ');
            pathInjectie.write('L $x $yInjectie ');
          }
        }

        // Draw lines
        svg.writeln(
          '<path d="$pathAfname" fill="none" stroke="blue" stroke-width="2" opacity="0.7"/>',
        );
        svg.writeln(
          '<path d="$pathInjectie" fill="none" stroke="red" stroke-width="2" opacity="0.7"/>',
        );
      }

      // Draw data points
      for (int i = 0; i < processedData.length; i++) {
        if (i % (processedData.length ~/ 100 + 1) == 0) {
          // Sample points for large datasets
          final dataPoint = processedData[i];
          final x =
              padding +
              (i /
                      (processedData.length - 1 > 0
                          ? processedData.length - 1
                          : 1)) *
                  graphWidth;
          final yAfname =
              height -
              padding -
              (dataPoint.volume_afname_kwh / maxVol) * graphHeight;
          final yInjectie =
              height -
              padding -
              (dataPoint.volume_injectie_kwh / maxVol) * graphHeight;

          svg.writeln(
            '<circle cx="$x" cy="$yAfname" r="3" fill="blue" opacity="0.6"/>',
          );
          svg.writeln(
            '<circle cx="$x" cy="$yInjectie" r="3" fill="red" opacity="0.6"/>',
          );
        }
      }

      // Legend
      const legendX = width - 250.0;
      const legendY = 60.0;
      svg.writeln(
        '<rect x="$legendX" y="$legendY" width="220" height="70" fill="white" stroke="black" stroke-width="1"/>',
      );
      svg.writeln(
        '<line x1="${legendX + 10}" y1="${legendY + 20}" x2="${legendX + 40}" y2="${legendY + 20}" stroke="blue" stroke-width="3"/>',
      );
      svg.writeln(
        '<text x="${legendX + 50}" y="${legendY + 25}" font-size="14" fill="black">Energy from net</text>',
      );
      svg.writeln(
        '<line x1="${legendX + 10}" y1="${legendY + 50}" x2="${legendX + 40}" y2="${legendY + 50}" stroke="red" stroke-width="3"/>',
      );
      svg.writeln(
        '<text x="${legendX + 50}" y="${legendY + 55}" font-size="14" fill="black">Energy to net</text>',
      );

      // Date range on X-axis
      if (processedData.isNotEmpty) {
        final startDateStr = DateFormat(
          'dd/MM/yy HH:mm',
        ).format(processedData.first.datetime);
        final endDateStr = DateFormat(
          'dd/MM/yy HH:mm',
        ).format(processedData.last.datetime);
        svg.writeln(
          '<text x="$padding" y="${height - 10}" font-size="12" text-anchor="start" fill="black">$startDateStr</text>',
        );
        svg.writeln(
          '<text x="${width - padding}" y="${height - 10}" font-size="12" text-anchor="end" fill="black">$endDateStr</text>',
        );
      }

      svg.writeln('</svg>');

      // Encode SVG to base64
      final svgBytes = utf8.encode(svg.toString());
      return base64Encode(svgBytes);
    } catch (e) {
      print('Error generating base64Image: $e');
      return '';
    }
  }

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
