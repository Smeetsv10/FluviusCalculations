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
  late int startDay;
  late int startMonth;
  late int startYear;
  late int endDay;
  late int endMonth;
  late int endYear;

  @override
  void initState() {
    super.initState();
    final gridData = Provider.of<GridData>(context, listen: false);

    final startParts = gridData.start_date.split('-').map(int.parse).toList();
    final endParts = gridData.end_date.split('-').map(int.parse).toList();

    startDay = startParts[0];
    startMonth = startParts[1];
    startYear = startParts[2];
    endDay = endParts[0];
    endMonth = endParts[1];
    endYear = endParts[2];
  }

  List<int> getDays(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(daysInMonth, (i) => i + 1);
  }

  List<int> getMonths() => List.generate(12, (i) => i + 1);

  List<int> getYears() {
    final currentYear = DateTime.now().year;
    return List.generate(21, (i) => currentYear - 20 + i);
  }

  Widget buildDateDropdown({
    required String title,
    required int selectedDay,
    required int selectedMonth,
    required int selectedYear,
    required ValueChanged<int> onDayChanged,
    required ValueChanged<int> onMonthChanged,
    required ValueChanged<int> onYearChanged,
  }) {
    final days = getDays(selectedYear, selectedMonth);
    final months = getMonths();
    final years = getYears();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(
          width: 80,
          child: DropdownButtonFormField<int>(
            value: selectedDay,
            isDense: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            ),
            items: days
                .map(
                  (d) => DropdownMenuItem(value: d, child: Text(d.toString())),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onDayChanged(value);
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('-'),
        ),
        SizedBox(
          width: 80,
          child: DropdownButtonFormField<int>(
            initialValue: selectedMonth,
            isDense: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            ),
            items: months
                .map(
                  (m) => DropdownMenuItem(value: m, child: Text(m.toString())),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onMonthChanged(value);
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('-'),
        ),
        SizedBox(
          width: 100,
          child: DropdownButtonFormField<int>(
            value: selectedYear,
            isDense: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            ),
            items: years
                .map(
                  (y) => DropdownMenuItem(value: y, child: Text(y.toString())),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onYearChanged(value);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridData = Provider.of<GridData>(context, listen: false);

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
              buildDateDropdown(
                title: 'Start Date (DD-MM-YYYY)',
                selectedDay: startDay,
                selectedMonth: startMonth,
                selectedYear: startYear,
                onDayChanged: (v) => setState(() {
                  startDay = v;
                  gridData.start_date = '$startDay-$startMonth-$startYear';
                }),
                onMonthChanged: (v) => setState(() {
                  startMonth = v;
                  gridData.start_date = '$startDay-$startMonth-$startYear';
                }),
                onYearChanged: (v) => setState(() {
                  startYear = v;
                  gridData.start_date = '$startDay-$startMonth-$startYear';
                }),
              ),
              const SizedBox(height: 16),
              buildDateDropdown(
                title: 'End Date (DD-MM-YYYY)',
                selectedDay: endDay,
                selectedMonth: endMonth,
                selectedYear: endYear,
                onDayChanged: (v) => setState(() {
                  endDay = v;
                  gridData.end_date = '$endDay-$endMonth-$endYear';
                }),
                onMonthChanged: (v) => setState(() {
                  endMonth = v;
                  gridData.end_date = '$endDay-$endMonth-$endYear';
                }),
                onYearChanged: (v) => setState(() {
                  endYear = v;
                  gridData.end_date = '$endDay-$endMonth-$endYear';
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: const Size(500, 50),
                ),
                onPressed: () {},
                child: const Text(
                  'Load CSV file',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
