import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';

class EnergyHistoryChart extends StatefulWidget {
  final List<double> importEnergyHistory;
  final List<double> exportEnergyHistory;
  final List<DateTime> timeValues; // X-axis labels

  const EnergyHistoryChart({
    super.key,
    required this.importEnergyHistory,
    required this.exportEnergyHistory,
    required this.timeValues,
  });

  @override
  State<EnergyHistoryChart> createState() => _EnergyHistoryChartState();
}

class _EnergyHistoryChartState extends State<EnergyHistoryChart> {
  late List<EnergyDataPoint> data;

  @override
  void initState() {
    super.initState();
    _generateChartData();
  }

  void _generateChartData() {
    data = [];
    for (int i = 0; i < widget.timeValues.length; i++) {
      data.add(
        EnergyDataPoint(
          datetime: widget.timeValues[i],
          volume_afname_kwh: widget.importEnergyHistory[i],
          volume_injectie_kwh: widget.exportEnergyHistory[i],
        ),
      );
    }
  }

  @override
  void didUpdateWidget(EnergyHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generateChartData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      width: 1000,
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(),
        primaryYAxis: NumericAxis(
          labelFormat: '{value}',
          labelStyle: const TextStyle(fontSize: 10),
        ),
        title: ChartTitle(
          text: 'Energy History',
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          overflowMode: LegendItemOverflowMode.wrap,
        ),
        series: <CartesianSeries>[
          // Renders line chart
          LineSeries<EnergyDataPoint, DateTime>(
            dataSource: data,
            xValueMapper: (EnergyDataPoint datapoint, _) => datapoint.datetime,
            yValueMapper: (EnergyDataPoint datapoint, _) =>
                datapoint.volume_afname_kwh,
            color: Colors.green,
            name: 'Import (kWh)',
          ),
          LineSeries<EnergyDataPoint, DateTime>(
            dataSource: data,
            xValueMapper: (EnergyDataPoint datapoint, _) => datapoint.datetime,
            yValueMapper: (EnergyDataPoint datapoint, _) =>
                datapoint.volume_injectie_kwh,
            color: Colors.red,
            name: 'Export (kWh)',
          ),
        ],
      ),
    );
  }
}
