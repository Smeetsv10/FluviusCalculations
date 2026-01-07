import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fluvius_calculations_flutter/classes/myGridData.dart';

class Sochistorychart extends StatefulWidget {
  final List<double> socHistory;
  final List<DateTime> timeValues; // X-axis labels

  const Sochistorychart({
    super.key,
    required this.socHistory,
    required this.timeValues,
  });

  @override
  State<Sochistorychart> createState() => _SochistorychartState();
}

class _SochistorychartState extends State<Sochistorychart> {
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
          volume_afname_kwh: widget.socHistory[i] * 100,
          volume_injectie_kwh: widget.socHistory[i] * 100,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(Sochistorychart oldWidget) {
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
          title: AxisTitle(text: 'SOC [%]'),
          labelFormat: '{value}',
          labelStyle: const TextStyle(fontSize: 10),
          minimum: 0,
          maximum: 100,
        ),
        title: ChartTitle(
          text: 'Battery SOC History',
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        series: <CartesianSeries>[
          // Renders line chart
          LineSeries<EnergyDataPoint, DateTime>(
            dataSource: data,
            xValueMapper: (EnergyDataPoint datapoint, _) => datapoint.datetime,
            yValueMapper: (EnergyDataPoint datapoint, _) =>
                datapoint.volume_afname_kwh,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
