import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatting/money_format.dart';
import '../../../ui/icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/widgets.dart';
import '../domain/ledger_report.dart';
import 'chart_scale.dart';

/// Donut of this month's spending, with a row for each category.
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
      return const EmptyState(
        icon: Icons.donut_large_outlined,
        title: 'No spending yet',
        message: 'Expenses this month will show up here.',
      );
    }
    final total = spending.fold<int>(0, (sum, item) => sum + item.spentMinor);
    final muted = AppColors.mutedOf(context);
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

/// Six months of income and spending. Transfers are not included.
class CashFlowChart extends StatelessWidget {
  const CashFlowChart({required this.trend, required this.currency, super.key});

  final List<MonthCashFlow> trend;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No cash flow yet',
      );
    }
    var peak = 0;
    for (final month in trend) {
      if (month.incomeMinor > peak) peak = month.incomeMinor;
      if (month.expenseMinor > peak) peak = month.expenseMinor;
    }
    final scale = ChartScale.fromZero(peak / 100);
    final muted = AppColors.mutedOf(context);
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: scale.max,
          minY: scale.min,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: scale.step,
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
                reservedSize: 56,
                interval: scale.step,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _tickLabel(value, scale, currency),
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

/// Net worth across the same six months as [CashFlowChart].
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
    if (points.length < 2) {
      return const EmptyState(
        icon: Icons.show_chart,
        title: 'Not enough history yet',
      );
    }
    var minMinor = points.first.minor;
    var maxMinor = points.first.minor;
    for (final point in points) {
      if (point.minor < minMinor) minMinor = point.minor;
      if (point.minor > maxMinor) maxMinor = point.minor;
    }
    final scale = ChartScale.around(minMinor / 100, maxMinor / 100);
    final color = Theme.of(context).colorScheme.primary;
    final muted = AppColors.mutedOf(context);
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: scale.min,
          maxY: scale.max,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: scale.step,
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
                reservedSize: 56,
                interval: scale.step,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _tickLabel(value, scale, currency),
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

String _tickLabel(double value, ChartScale scale, String currency) {
  if (scale.step <= 0) return '';
  final index = ((value - scale.min) / scale.step).round();
  final tick = scale.min + index * scale.step;
  if ((tick - value).abs() > scale.step * 0.01) return '';
  if (tick < scale.min - scale.step * 0.01) return '';
  if (tick > scale.max + scale.step * 0.01) return '';
  return formatAxisAmount((tick * 100).round(), currency);
}
