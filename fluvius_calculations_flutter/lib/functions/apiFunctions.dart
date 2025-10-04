// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// const String apiBaseUrl = 'http://127.0.0.1:8000';

// Future<void> pickFiles() async {
//   if (_isBrowsing) return; // Prevent multiple clicks

//   try {
//     setState(() {
//       _isBrowsing = true;
//     });

//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['csv'],
//       withData: true, // This is important to get file bytes
//     );

//     if (result != null && result.files.isNotEmpty) {
//       final PlatformFile file = result.files.first;

//       setState(() {
//         selectedFile = file;
//         csvFileBytes = file.bytes; // Get file bytes directly

//         // Update file path display
//         if (kIsWeb) {
//           filePathController.text =
//               "📤 ${file.name} (${file.bytes?.length ?? 0} bytes)";
//         } else {
//           String filePath = file.path ?? file.name;
//           filePathController.text = filePath;
//         }
//       });

//       print('🔍 DEBUG: File selected: ${file.name}');
//       print('🔍 DEBUG: File size: ${file.bytes?.length ?? 0} bytes');
//       print('🔍 DEBUG: File path: ${file.path ?? "N/A"}');

//       // Debug: Show first 200 characters of CSV
//       if (csvFileBytes != null) {
//         try {
//           String csvContent = String.fromCharCodes(csvFileBytes!);
//           print(
//             '🔍 DEBUG: CSV preview (first 200 chars): ${csvContent.length > 200 ? csvContent.substring(0, 200) : csvContent}',
//           );
//         } catch (e) {
//           print('🔍 DEBUG: Could not preview CSV content: $e');
//         }
//       }
//     } else {
//       print('🔍 DEBUG: No file selected');
//     }
//   } catch (e) {
//     print('❌ Error picking file: $e');
//     _showErrorDialog('File Selection Error', 'Failed to select file: $e');
//   } finally {
//     setState(() {
//       _isBrowsing = false;
//     });
//   }
// }

// Future<void> loadData() async {
//   if (_isLoading) return;

//   try {
//     setState(() {
//       _isLoading = true;
//     });

//     // Validate required fields
//     if (csvFileBytes == null && filePathController.text.isEmpty) {
//       _showErrorDialog('Validation Error', 'Please select a CSV file first.');
//       return;
//     }

//     print('🔍 DEBUG: Starting loadData...');
//     print('🔍 DEBUG: CSV bytes available: ${csvFileBytes != null}');
//     print('🔍 DEBUG: CSV bytes length: ${csvFileBytes?.length ?? 0}');
//     print('🔍 DEBUG: File path: ${filePathController.text}');

//     // Convert CSV bytes to base64 string
//     String? csvDataB64;
//     if (csvFileBytes != null) {
//       csvDataB64 = base64Encode(csvFileBytes!);
//       print('🔍 DEBUG: Base64 encoded CSV length: ${csvDataB64.length}');
//       print(
//         '🔍 DEBUG: Base64 preview (first 100 chars): ${csvDataB64.length > 100 ? csvDataB64.substring(0, 100) : csvDataB64}',
//       );
//     }

//     // Construct SimulationRequest from form values
//     final requestBody = {
//       'start_date': startDateController.text,
//       'end_date': endDateController.text,
//       'location': locationController.text,
//       'injection_price': _parseDouble(injectionPriceController.text) ?? 0.04,
//       'price_per_kWh': _parseDouble(pricePerKWhController.text) ?? 0.35,
//       'battery_capacity': _parseDouble(batteryCapacityController.text) ?? 0.0,
//       'battery_lifetime': _parseInt(batteryLifetimeController.text) ?? 10,
//       'price_per_kWh_battery':
//           _parseDouble(pricePerKWhBatteryController.text) ?? 700.0,
//       'efficiency': _parseDouble(efficiencyController.text) ?? 0.95,
//       'C_rate': _parseDouble(cRateController.text) ?? 0.0625,
//       'dynamic': _parseBool(dynamicController.text),
//       'flag_EV': _parseBool(flagEVController.text),
//       'flag_PV': _parseBool(flagPVController.text),
//       'EAN_ID': eanIdController.text.isEmpty
//           ? -1
//           : _parseInt(eanIdController.text) ?? -1,
//       'file_path': selectedFile?.name ?? filePathController.text,
//       'csv_data': csvDataB64, // Send CSV data as base64 string
//     };

//     print('🔍 DEBUG: Request body keys: ${requestBody.keys.toList()}');
//     print('🔍 DEBUG: CSV data included: ${csvDataB64 != null}');
//     print('🔍 DEBUG: API URL: $apiBaseUrl/load_data');

//     // Make API call
//     final response = await http.post(
//       Uri.parse('$apiBaseUrl/load_data'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(requestBody),
//     );

//     print('🔍 DEBUG: Response status: ${response.statusCode}');
//     print('🔍 DEBUG: Response body: ${response.body}');

//     if (response.statusCode == 200) {
//       final responseData = jsonDecode(response.body);
//       if (responseData.containsKey('error')) {
//         _showErrorDialog('API Error', responseData['error']);
//       } else {
//         String message = responseData['message'] ?? 'Data loaded successfully';

//         // Add data info if available
//         if (responseData.containsKey('data_info')) {
//           final dataInfo = responseData['data_info'];
//           message += '\n\nData Info:';
//           message += '\n• Records: ${dataInfo['records']}';
//           message += '\n• Columns: ${dataInfo['columns']?.join(', ') ?? 'N/A'}';
//           if (dataInfo['date_range'] != null) {
//             message +=
//                 '\n• Date range: ${dataInfo['date_range']['start']} to ${dataInfo['date_range']['end']}';
//           }
//           setState(() {
//             startDateController.text = dataInfo['date_range']['start'] ?? '';
//             endDateController.text = dataInfo['date_range']['end'] ?? '';
//           });
//         }

//         _showSuccessDialog('Success', message);
//       }
//     } else {
//       _showErrorDialog(
//         'HTTP Error',
//         'Request failed with status: ${response.statusCode}\nResponse: ${response.body}',
//       );
//     }
//   } catch (e) {
//     print('❌ Error in loadData: $e');
//     _showErrorDialog('Network Error', 'Failed to connect to API: $e');
//   } finally {
//     setState(() {
//       _isLoading = false;
//     });
//   }
// }
