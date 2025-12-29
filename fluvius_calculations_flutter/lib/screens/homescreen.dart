import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:fluvius_calculations_flutter/functions/helperFunctions.dart';
import 'package:fluvius_calculations_flutter/screens/batteryParameterScreen.dart';
import 'package:fluvius_calculations_flutter/screens/gridDataParametersScreen.dart';
import 'package:fluvius_calculations_flutter/screens/houseParametersScreen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> processData() async => _withLoading(() async {
    try {
      final house = context.read<House>();
      house.grid_data.processCSVData();
      ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(
          '✅ CSV processed! Found ${house.grid_data.processedData.length} entries.',
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar('Failed: $e'));
    }
  });

  Future<void> visualizeData() async => _withLoading(() async {
    try {
      final house = context.read<House>();
      if (house.grid_data.base64Image.isNotEmpty) {
        showPlotDialog([house.grid_data.base64Image], context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar('Failed: $e'));
    }
  });

  Future<void> simulateHousehold() async => _withLoading(() async {
    try {
      final house = context.read<House>();
      dynamic result = house.simulateHousehold();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(mySnackBar('✅${result['message']}'));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar('Failed: $e'));
    }
  });

  Future<void> optimizeBattery() async => _withLoading(() async {});

  Future<void> visualizeSimulation() async => _withLoading(() async {
    try {
      final house = context.read<House>();
      if (house.base64Figure.isNotEmpty) {
        showPlotDialog([
          house.grid_data.base64Image,
          house.base64Figure,
          house.battery.base64Figure,
        ], context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar('Failed: $e'));
    }
  });

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
                      child: const Text('Simulate Household'),
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
