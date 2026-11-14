import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatting/money_format.dart';
import '../../../ui/icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../domain/ledger_report.dart';

class SpendingPie extends StatelessWidget {
  const SpendingPie({
    required this.spending,
    required this.currency,
    super.key,
  });

  final List<CategorySpend> spending;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (spending.isEmpty) {
      return const Text('No spending in this month yet.');
    }
    final total = spending.fold<int>(0, (sum, item) => sum + item.spentMinor);
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMuted
        : AppColors.muted;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 52,
                  pieTouchData: PieTouchData(enabled: false),
                  sections: <PieChartSectionData>[
                    for (final item in spending)
                      PieChartSectionData(
                        value: item.spentMinor.toDouble(),
                        color: Color(item.color),
                        radius: 28,
                        showTitle: false,
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 250),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Spent', style: TextStyle(color: muted, fontSize: 12)),
                  Text(
                    formatCompactMinor(total, currency),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final item in spending)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                Icon(
                  categoryIcon(item.iconKey),
                  size: 18,
                  color: Color(item.color),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(item.name)),
                Text(formatMinor(item.spentMinor, currency)),
              ],
            ),
          ),
      ],
    );
  }
}

class CashFlowChart extends StatelessWidget {
  const CashFlowChart({required this.trend, required this.currency, super.key});

  final List<MonthCashFlow> trend;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();
    var peak = 0;
    for (final month in trend) {
      if (month.incomeMinor > peak) peak = month.incomeMinor;
      if (month.expenseMinor > peak) peak = month.expenseMinor;
    }
    final maxY = peak == 0 ? 1.0 : peak / 100 * 1.25;
    final interval = maxY / 3;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMuted
        : AppColors.muted;
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    formatCompactMinor((value * 100).round(), currency),
                    style: TextStyle(color: muted, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= trend.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatShortMonth(trend[index].month.month),
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: <BarChartGroupData>[
            for (var i = 0; i < trend.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: trend[i].incomeMinor / 100,
                    color: AppColors.income,
                    width: 8,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  BarChartRodData(
                    toY: trend[i].expenseMinor / 100,
                    color: AppColors.expense,
                    width: 8,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}

class NetWorthChart extends StatelessWidget {
  const NetWorthChart({
    required this.points,
    required this.currency,
    super.key,
  });

  final List<NetWorthPoint> points;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const Text('Not enough history yet.');
    var minMinor = points.first.minor;
    var maxMinor = points.first.minor;
    for (final point in points) {
      if (point.minor < minMinor) minMinor = point.minor;
      if (point.minor > maxMinor) maxMinor = point.minor;
    }
    final padding = ((maxMinor - minMinor).abs() * 0.15)
        .round()
        .clamp(100, 1 << 30)
        .toInt();
    final minY = (minMinor - padding) / 100;
    final maxY = (maxMinor + padding) / 100;
    final interval = (maxY - minY) / 3;
    final color = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMuted
        : AppColors.muted;
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval == 0 ? 1 : interval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Theme.of(context).dividerColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: interval == 0 ? 1 : interval,
                getTitlesWidget: (value, meta) {
                  return Text(
                    formatCompactMinor((value * 100).round(), currency),
                    style: TextStyle(color: muted, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if ((value - index).abs() > 0.01) {
                    return const SizedBox.shrink();
                  }
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatShortMonth(points[index].month.month),
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: <FlSpot>[
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].minor / 100),
              ],
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
