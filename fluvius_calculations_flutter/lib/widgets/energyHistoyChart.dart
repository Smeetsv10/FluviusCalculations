import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EnergyHistoryChart extends StatelessWidget {
  final List<double> importEnergyHistory;
  final List<double> exportEnergyHistory;
  final List<String> timeValues; // X-axis labels

  const EnergyHistoryChart({
    super.key,
    required this.importEnergyHistory,
    required this.exportEnergyHistory,
    required this.timeValues,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = [
      ...importEnergyHistory,
      ...exportEnergyHistory,
    ].fold<double>(0, (prev, e) => e > prev ? e : prev);

    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (importEnergyHistory.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= timeValues.length)
                    return const SizedBox();
                  // Show only every Nth label if too crowded
                  if (timeValues.length > 10 &&
                      index % (timeValues.length ~/ 10) != 0) {
                    return const SizedBox();
                  }
                  return Text(
                    timeValues[index],
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: importEnergyHistory
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: exportEnergyHistory
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
