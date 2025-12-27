import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/apiService.dart';
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
  bool _isTestingAPI = false;

  Future<void> _withLoading(Future<void> Function() action) async {
    final gridData = context.read<GridData>();
    if (gridData.csvFileBytes == null) {
      showMyDialog(
        'No CSV Selected',
        'Please select a CSV file in the Grid Data section before sending data.',
        context,
      );
      return;
    }

    setState(() => gridData.isLoading = true);
    try {
      await action();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar('Failed: $e'));
    } finally {
      setState(() => gridData.isLoading = false);
    }
  }

  Future<void> testAPI() async {
    setState(() => _isTestingAPI = true);
    try {
      final response = await ApiService.testConnection();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(mySnackBar('✅ API Test Success: ${response['message']}'));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(mySnackBar('❌ ERROR: API Test Failed: $e'));
    } finally {
      setState(() => _isTestingAPI = false);
    }
  }

  Future<void> processData() async => _withLoading(() async {
    final house = context.read<House>();
    final response = await ApiService.sendHouseData(house);

    if (response['data_info']?['date_range'] != null) {
      final startDate = DateTime.parse(
        response['data_info']['date_range']['start'],
      );
      final endDate = DateTime.parse(
        response['data_info']['date_range']['end'],
      );
      context.read<GridData>().updateParameters(
        newStartDate: startDate,
        newEndDate: endDate,
        newMinStartDate: startDate,
        newMaxEndDate: endDate,
      );
      setState(() {});
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(mySnackBar(response['message'] ?? 'Success!'));
  });

  Future<void> visualizeData() async => _withLoading(() async {
    Stopwatch stopwatch = Stopwatch()..start();
    final house = context.read<House>();
    dynamic response = {};
    if (house.grid_data.base64Image.isNotEmpty) {
      showPlotDialog(house.grid_data.base64Image, context);
    } else {
      response = await ApiService.visualizeHouseData(house);
      showPlotDialog(house.grid_data.base64Image, context);
    }
    stopwatch.stop();
    print('Visualize Data took: ${stopwatch.elapsedMilliseconds} ms');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(mySnackBar(response['message'] ?? 'Success!'));
  });

  Future<void> simulateHousehold() async => _withLoading(() async {
    final house = context.read<House>();
    final response = await ApiService.simulateHouse(house);

    if (response.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar(response['error']));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(mySnackBar(response['message'] ?? 'Success!'));
  });

  Future<void> optimizeBattery() async => _withLoading(() async {
    final house = context.read<House>();
    final response = await ApiService.optimizeBattery(house);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(mySnackBar(response['message'] ?? 'Success!'));
  });

  Future<void> visualizeSimulation() async => _withLoading(() async {
    final house = context.read<House>();
    dynamic response = {};

    if (house.base64Figure.isNotEmpty) {
      print('plotting local value');
      showPlotDialog(house.base64Figure, context);
    } else {
      response = await ApiService.visualizeSimulation(house);
      showPlotDialog(house.grid_data.base64Image, context);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(mySnackBar(response['message'] ?? 'Success!'));
  });

  Future<void> simulateLocalHousehold() async {
    final house = context.read<House>();

    setState(() => context.read<GridData>().isLoading = true);

    try {
      // First parse CSV data if available
      if (house.grid_data.csvFileBytes != null) {
        house.grid_data.parseCSVData();

        if (house.grid_data.processedData.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            mySnackBar('No data found in CSV. Please check CSV format.'),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(mySnackBar('Please select a CSV file first.'));
        return;
      }

      // Run local simulation
      final result = house.simulateHousehold();

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          mySnackBar(
            '✅ Local simulation completed! '
            'Import: ${house.import_cost.toStringAsFixed(2)}€, '
            'Export: ${house.export_revenue.toStringAsFixed(2)}€, '
            'Net: ${house.energy_cost.toStringAsFixed(2)}€',
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(mySnackBar('❌ Simulation failed: ${result['message']}'));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(mySnackBar('❌ Local simulation error: $e'));
    } finally {
      setState(() => context.read<GridData>().isLoading = false);
    }
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
                    const HouseParameterScreen(),
                    const SizedBox(height: 20),
                    const BatteryParameterScreen(),
                    const SizedBox(height: 20),
                    const GridDataParameterScreen(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        print('House fig:');
                        print(
                          context.read<House>().base64Figure.length > 10
                              ? context.read<House>().base64Figure.substring(
                                  0,
                                  10,
                                )
                              : context.read<House>().base64Figure,
                        );
                        print('GridData:');
                        print(
                          gridData.base64Image.length > 10
                              ? gridData.base64Image.substring(0, 10)
                              : gridData.base64Image,
                        );
                        print('------------------------------');
                      },
                      child: const Text('Print House JSON'),
                    ),
                    TextButton(
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
                    Divider(),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: gridData.isLoading ? null : processData,
                      child: const Text('Process Data'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading ? null : visualizeData,
                      child: const Text('Visualize Data'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading ? null : simulateHousehold,
                      child: const Text('Simulate Household (API)'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading
                          ? null
                          : simulateLocalHousehold,
                      child: const Text('Simulate Household (Local)'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading
                          ? null
                          : visualizeSimulation,
                      child: const Text('Plot Simulation Results'),
                    ),
                    TextButton(
                      onPressed: gridData.isLoading ? null : optimizeBattery,
                      child: const Text('Optimize Battery'),
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
