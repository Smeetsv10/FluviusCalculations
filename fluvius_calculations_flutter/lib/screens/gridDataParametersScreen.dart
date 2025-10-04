import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';
import 'package:fluvius_calculations_flutter/classes/myHouse.dart';
import 'package:fluvius_calculations_flutter/functions/dateSelectionWidget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fluvius_calculations_flutter/functions/helperFunctions.dart';

class GridDataParameterScreen extends StatefulWidget {
  const GridDataParameterScreen({super.key});

  @override
  State<GridDataParameterScreen> createState() =>
      _GridDataParameterScreenState();
}

class _GridDataParameterScreenState extends State<GridDataParameterScreen> {
  late TextEditingController filePathController;
  late TextEditingController startDateController;
  late TextEditingController endDateController;

  @override
  void initState() {
    super.initState();
    final grid_data = Provider.of<GridData>(context, listen: false);

    filePathController = TextEditingController(text: grid_data.file_path);
    startDateController = TextEditingController(text: grid_data.start_date);
    endDateController = TextEditingController(text: grid_data.end_date);
  }

  @override
  void dispose() {
    filePathController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  Widget fileSelectionWidget() {
    return TextButton(onPressed: null, child: const Text('Select File'));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GridData>(
      builder: (context, grid_data, child) {
        return ExpansionTile(
          title: const Text(
            "Grid Data Parameters",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                children: [
                  fileSelectionWidget(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DateSelectionWidget(
                          title: 'Start Date (dd-mm-yyyy)',
                          controller: startDateController,
                        ),
                      ),

                      const SizedBox(width: 16),
                      Expanded(
                        child: DateSelectionWidget(
                          title: 'End Date (dd-mm-yyyy)',
                          controller: endDateController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
