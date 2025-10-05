import 'package:flutter/material.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';
import 'package:provider/provider.dart';

class GridDataParameterScreen extends StatefulWidget {
  const GridDataParameterScreen({super.key});

  @override
  State<GridDataParameterScreen> createState() =>
      _GridDataParameterScreenState();
}

class _GridDataParameterScreenState extends State<GridDataParameterScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GridData>(
      builder: (context, gridData, child) {
        // Helper to update DateTime without repeating all fields
        void updateDateTime({
          required bool isStart,
          int? day,
          int? month,
          int? year,
          int? hour,
          int? minute,
        }) {
          final current = isStart ? gridData.start_date : gridData.end_date;
          final newDate = DateTime(
            year ?? current.year,
            month ?? current.month,
            day ?? current.day,
            hour ?? current.hour,
            minute ?? current.minute,
          );
          if (isStart) {
            gridData.updateParameters(newStartDate: newDate);
          } else {
            gridData.updateParameters(newEndDate: newDate);
          }
        }

        // Dropdown builder
        Widget buildDateTimeDropdown({
          required String title,
          required bool isStart,
          required DateTime selected,
        }) {
          List<int> getDaysInMonth(int y, int m) =>
              List.generate(DateTime(y, m + 1, 0).day, (i) => i + 1);

          final days = getDaysInMonth(selected.year, selected.month);
          final months = List.generate(12, (i) => i + 1);
          final years = List.generate(21, (i) => DateTime.now().year - 20 + i);
          final hours = List.generate(24, (i) => i);
          final minutes = List.generate(4, (i) => i * 15);

          Widget buildDropdown({
            required int value,
            required List<int> items,
            required ValueChanged<int> onChanged,
            double width = 70,
          }) => SizedBox(
            width: width,
            child: DropdownButtonFormField<int>(
              initialValue: value,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 4,
                ),
              ),
              items: items
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.toString().padLeft(2, '0')),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              buildDropdown(
                value: selected.day,
                items: days,
                onChanged: (v) => updateDateTime(isStart: isStart, day: v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('-'),
              ),
              buildDropdown(
                value: selected.month,
                items: months,
                onChanged: (v) => updateDateTime(isStart: isStart, month: v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('-'),
              ),
              buildDropdown(
                value: selected.year,
                items: years,
                onChanged: (v) => updateDateTime(isStart: isStart, year: v),
                width: 100,
              ),
              const SizedBox(width: 20),
              buildDropdown(
                value: selected.hour,
                items: hours,
                onChanged: (v) => updateDateTime(isStart: isStart, hour: v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(':'),
              ),
              buildDropdown(
                value: selected.minute,
                items: minutes,
                onChanged: (v) => updateDateTime(isStart: isStart, minute: v),
              ),
            ],
          );
        }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDateTimeDropdown(
                    title: 'Start Date (DD-MM-YYYY hh:mm)',
                    isStart: true,
                    selected: gridData.start_date,
                  ),
                  const SizedBox(height: 16),
                  buildDateTimeDropdown(
                    title: 'End Date (DD-MM-YYYY hh:mm)',
                    isStart: false,
                    selected: gridData.end_date,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // File path display (takes 4x space)
                      Expanded(
                        flex: 4,
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: gridData.file_path.isEmpty
                                ? 'No file selected'
                                : gridData.file_path,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Selected CSV File',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                          style: TextStyle(
                            color: gridData.file_path.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Load CSV button (takes 1x space)
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            minimumSize: const Size.fromHeight(50),
                            overlayColor: Colors.white,
                          ),
                          onPressed: () async {
                            if (gridData.isLoading) {
                              return;
                            } else {
                              try {
                                final success = await gridData.pickFiles();
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '✅ File loaded successfully',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('⚠️ No file selected'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Error: $e'),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Load CSV File',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
