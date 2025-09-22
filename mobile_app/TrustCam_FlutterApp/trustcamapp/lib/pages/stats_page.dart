import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/stats_chart.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stats")),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: StatsChart(),
      ),
    );
  }
}
