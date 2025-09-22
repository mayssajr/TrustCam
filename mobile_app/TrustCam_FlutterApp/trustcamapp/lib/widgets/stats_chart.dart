import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatsChart extends StatelessWidget {
  const StatsChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: Colors.blue)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 3, color: Colors.blue)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 7, color: Colors.blue)]),
        ],
      ),
    );
  }
}
