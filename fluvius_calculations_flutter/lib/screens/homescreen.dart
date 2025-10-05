import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/apiService.dart';
import 'package:fluvius_calculations_flutter/classes/myBattery.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:fluvius_calculations_flutter/functions/helperFunctions.dart';
import 'package:fluvius_calculations_flutter/screens/batteryParameterScreen.dart';
import 'package:fluvius_calculations_flutter/screens/gridDataParametersScreen.dart';
import 'package:fluvius_calculations_flutter/screens/houseParametersScreen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBrowsing = false; // Loading state for Browse button
  bool _isTestingAPI = false; // Loading state for API test

  Future<void> testAPI() async {
    setState(() {
      _isTestingAPI = true;
    });

    try {
      final response = await ApiService.testConnection();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ API Test Success: ${response['message']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ API Test Failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isTestingAPI = false;
      });
    }
  }

  Future<void> processData() async {
    Provider.of<GridData>(context, listen: false).isLoading = true;
    if (Provider.of<GridData>(context, listen: false).csvFileBytes == null) {
      showMyDialog(
        'No CSV Selected',
        'Please select a CSV file in the Grid Data section before sending data.',
        context,
      );

      Provider.of<GridData>(context, listen: false).isLoading = false;
      return;
    }
    try {
      final house = context.read<House>();
      final response = await ApiService.sendHouseData(house);
      print(response);

      // process response and update House state
      if (response['data_info'] != null &&
          response['data_info']['date_range'] != null) {
        DateTime startDate = DateTime.parse(
          response['data_info']['date_range']['start'],
        );
        DateTime endDate = DateTime.parse(
          response['data_info']['date_range']['end'],
        );
        Provider.of<GridData>(context, listen: false).updateParameters(
          newStartDate: startDate,
          newEndDate: endDate,
          newMinStartDate: startDate,
          newMaxEndDate: endDate,
        );
        setState(() {});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Success!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      Provider.of<GridData>(context, listen: false).isLoading = false;
    }
  }

  Future<void> vizualizeData() async {
    void _showPlotDialog(String base64Image) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: 800,
            height: 600,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Data Visualization',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Image.memory(
                    base64Decode(base64Image),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Provider.of<GridData>(context, listen: false).isLoading = true;
    if (Provider.of<GridData>(context, listen: false).csvFileBytes == null) {
      showMyDialog(
        'No CSV Selected',
        'Please select a CSV file in the Grid Data section before sending data.',
        context,
      );
      Provider.of<GridData>(context, listen: false).isLoading = false;
      return;
    }
    try {
      final house = context.read<House>();
      final response = await ApiService.vizualizeHouseData(house);

      house.grid_data.base64Image = response['plot_data'];
      _showPlotDialog(house.grid_data.base64Image);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Success!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      Provider.of<GridData>(context, listen: false).isLoading = false;
    }
  }

  Future<void> simulateHousehold() async {
    // Placeholder for simulate functionality
    showMyDialog(
      'Not Implemented',
      'Simulate household functionality not yet implemented.',
      context,
    );
  }

  Future<void> optimizeBattery() async {
    // Placeholder for optimize functionality
    showMyDialog(
      'Not Implemented',
      'Optimize battery functionality not yet implemented.',
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home Battery Sizing Tool',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<GridData>(
        builder: (context, gridData, child) {
          return Stack(
            children: [
              if (gridData.isLoading)
                Container(
                  color: const Color.fromARGB(69, 0, 0, 0),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- House Parameters Section ---
                    const HouseParameterScreen(),
                    const SizedBox(height: 20),
                    // --- Battery Parameters Section ---
                    const BatteryParameterScreen(),
                    const SizedBox(height: 20),
                    // --- Grid Data Parameters Section ---
                    const GridDataParameterScreen(),
                    const SizedBox(height: 20),

                    // --- Debug / Print JSON ---
                    ElevatedButton(
                      onPressed: () {
                        print(
                          Provider.of<House>(context, listen: false).toJson(),
                        );
                      },
                      child: const Text('Print House JSON'),
                    ),

                    ElevatedButton(
                      onPressed: _isTestingAPI ? null : testAPI,
                      child: Wrap(
                        children: [
                          _isTestingAPI
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_protected_setup),
                          Text(
                            _isTestingAPI
                                ? 'Testing...'
                                : '🔧 Test API Connection',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Functional buttons
                    ElevatedButton(
                      onPressed: processData,
                      child: const Text('Process Data'),
                    ),
                    ElevatedButton(
                      onPressed: vizualizeData,
                      child: const Text('Visualize Data'),
                    ),
                    ElevatedButton(
                      onPressed: null,
                      child: const Text('Simulate Household (TBD)'),
                    ),
                    ElevatedButton(
                      onPressed: null,
                      child: const Text('Optimize Battery (TBD)'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
