import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/category_visuals.dart';
import '../../../../shared/models/spending_category.dart';

/// A donut chart rendering each [SpendingCategory]'s share of total
/// spending. Reused at large size on the dashboard and at small size inside
/// the chat's category breakdown card.
class SpendingDonutChart extends StatelessWidget {
  const SpendingDonutChart({
    super.key,
    required this.categories,
    this.size = 120,
    this.strokeWidth = 16,
    this.centerChild,
  });

  final List<SpendingCategory> categories;
  final double size;
  final double strokeWidth;
  final Widget? centerChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 2,
              centerSpaceRadius: size / 2 - strokeWidth,
              sections: [
                for (final category in categories)
                  PieChartSectionData(
                    value: category.amount,
                    color: categoryVisuals[category.type]!.color,
                    radius: strokeWidth,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          ?centerChild,
        ],
      ),
    );
  }
}
