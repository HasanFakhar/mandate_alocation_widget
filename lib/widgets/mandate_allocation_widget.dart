import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dart:math';
import '../controllers/mandate_controller.dart';
import '../models/mandate_model.dart';

class MandateAllocationWidget extends StatelessWidget {
  const MandateAllocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MandateController>();

    return Obx(() {
      final allClasses = ctrl.allocationByAssetClass.keys.toList();

      if (allClasses.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final withinCount = allClasses.where((c) {
        return ctrl.isWithinMandate(c);
      }).length;
      final breachCount = allClasses.length - withinCount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PortfolioTrendWidget(
            totalValue: ctrl.totalPortfolioValue,
            isCompliant: breachCount == 0,
          ),
          const SizedBox(height: 16),
          _WidgetHeader(
            assetClassCount: allClasses.length,
            withinCount: withinCount,
            breachCount: breachCount,
          ),
          const SizedBox(height: 16),
          const _Legend(),
          const SizedBox(height: 12),
          ...allClasses.map(
            (assetClass) => _AllocationRow(
              assetClass: assetClass,
              actual: ctrl.actualAllocation(assetClass),
              marketValue: ctrl.marketValue(assetClass),
              mandate: ctrl.mandateFor(assetClass),
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _WidgetHeader extends StatelessWidget {
  final int assetClassCount;
  final int withinCount;
  final int breachCount;

  const _WidgetHeader({
    required this.assetClassCount,
    required this.withinCount,
    required this.breachCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Mandate Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (breachCount > 0)
                _StatusBadge(
                  label: '$breachCount breach${breachCount > 1 ? 'es' : ''}',
                  color: _MandateColors.breach,
                  icon: Icons.warning_amber_rounded,
                )
              else
                _StatusBadge(
                  label: 'All within mandate',
                  color: _MandateColors.within,
                  icon: Icons.check_circle_outline_rounded,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PerformanceGauge(
                withinCount: withinCount,
                breachCount: breachCount,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderStat(
                      label: 'Asset classes',
                      value: '$assetClassCount',
                    ),
                    const SizedBox(height: 12),
                    _HeaderStat(
                      label: 'Within mandate',
                      value: '$withinCount / $assetClassCount',
                      valueColor: withinCount == assetClassCount
                          ? _MandateColors.within
                          : _MandateColors.breach,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HeaderStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio Trend Widget
// ─────────────────────────────────────────────────────────────────────────────

class _PortfolioTrendWidget extends StatelessWidget {
  final double totalValue;
  final bool isCompliant;

  const _PortfolioTrendWidget({
    required this.totalValue,
    required this.isCompliant,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = isCompliant
        ? _MandateColors.within
        : _MandateColors.breach;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          // Background chart
          Positioned.fill(child: _TrendChart(isCompliant: isCompliant)),
          // Content overlay
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Portfolio Value',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(totalValue),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCompliant ? '✓ Compliant' : '⚠ Breach Detected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final bool isCompliant;

  const _TrendChart({required this.isCompliant});

  List<FlSpot> _generateSpots() {
    if (isCompliant) {
      // Upward trend
      return [
        const FlSpot(0, 2),
        const FlSpot(1, 4),
        const FlSpot(2, 6),
        const FlSpot(3, 2),
        const FlSpot(4, 10),
        const FlSpot(5, 8),
      ];
    } else {
      // Downward trend
      return [
        const FlSpot(0, 10),
        const FlSpot(1, 2),
        const FlSpot(2, 3),
        const FlSpot(3, 6),
        const FlSpot(4, 3),
        const FlSpot(5, 1),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isCompliant ? _MandateColors.within : _MandateColors.breach;
    final spots = _generateSpots();

    return SizedBox(
      width: 120,
      height: 60,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.15),
              ),
            ),
          ],
          minX: 0,
          maxX: 5,
          minY: 0,
          maxY: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Performance Gauge
// ─────────────────────────────────────────────────────────────────────────────

class _PerformanceGauge extends StatelessWidget {
  final int withinCount;
  final int breachCount;

  const _PerformanceGauge({
    required this.withinCount,
    required this.breachCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = withinCount + breachCount;
    final performancePercent = total > 0 ? (withinCount / total) * 100 : 0.0;
    final isOptimal = breachCount == 0;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isOptimal
                    ? _MandateColors.within
                    : _MandateColors.breach,
                width: 3,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: performancePercent / 100,
              strokeWidth: 8,
              backgroundColor: const Color(0xFF3A3A3A),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOptimal ? _MandateColors.within : _MandateColors.breach,
              ),
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${performancePercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Compliant',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: const [
        // _LegendItem(
        //   color: _MandateColors.mandateRange,
        //   label: 'Allowed range',
        //   shape: _LegendShape.rect,
        // ),
        // _LegendItem(
        //   color: _MandateColors.strategic,
        //   label: 'Strategic target',
        //   shape: _LegendShape.line,
        // ),
        _LegendItem(
          color: _MandateColors.actualWithin,
          label: 'Actual (within)',
          shape: _LegendShape.circle,
        ),
        _LegendItem(
          color: _MandateColors.breach,
          label: 'Over limit',
          shape: _LegendShape.circle,
        ),
        _LegendItem(
          color: _MandateColors.underColor,
          label: 'Under limit',
          shape: _LegendShape.circle,
        ),
      ],
    );
  }
}

enum _LegendShape { rect, line, circle }

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final _LegendShape shape;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget indicator;

    switch (shape) {
      case _LegendShape.rect:
        indicator = Container(
          width: 16,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case _LegendShape.line:
        indicator = SizedBox(
          width: 16,
          height: 10,
          child: Center(child: Container(width: 2, height: 10, color: color)),
        );
      case _LegendShape.circle:
        indicator = Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final String assetClass;
  final double actual;
  final double marketValue;
  final MandateModel? mandate;

  const _AllocationRow({
    required this.assetClass,
    required this.actual,
    required this.marketValue,
    required this.mandate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double min = mandate?.min ?? 0;
    final double max = mandate?.max ?? 100;
    final double strategic = mandate?.strategic ?? ((min + max) / 2);
    final bool hasMandateData = mandate != null;
    final bool isOver = hasMandateData && actual > max;
    final bool isUnder = hasMandateData && actual < min;
    final bool isBreach = isOver || isUnder;
    final double diff = isOver ? (actual-max) : isUnder ?  (min-actual) : 0;

    final Color cardBackground = isOver
        ? _MandateColors.breach.withAlpha(30)
        : isUnder
        ? _MandateColors.underColor.withAlpha(30)
        : hasMandateData
        ? _MandateColors.within.withAlpha(30)
        : theme.colorScheme.surfaceContainerLow;

    final Color cardBorderColor = isOver
        ? _MandateColors.breach
        : isUnder
        ? _MandateColors.underColor
        : hasMandateData
        ? _MandateColors.within
        : theme.colorScheme.surfaceContainerLow;

    final Color actualColor = isOver
        ? _MandateColors.breach
        : isUnder
        ? _MandateColors.underColor
        : _MandateColors.actualWithin;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],

        color: cardBackground,
        border: Border.all(color: cardBorderColor, width: isBreach ? 1.5 : 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: assetClass / market value / actual / badge ────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    assetClass,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Text(
                //   _formatCurrency(marketValue),
                //   style: theme.textTheme.titleMedium?.copyWith(
                //     fontWeight: FontWeight.bold,
                //     color: theme.colorScheme.onSurface,
                //   ),
                // ),
                _MandateNumber(
                  label: _formatCurrency(marketValue),
                  value: actual,
                  color: actualColor,
                ),

                const SizedBox(width: 12),

                _ComplianceBadge(
                  diff: diff,
                  isOver: isOver,
                  isUnder: isUnder,
                  hasMandateData: hasMandateData,
                ),
              ],
            ),

            const SizedBox(height: 10),

            hasMandateData
                ? _RadialGauge(
                    min: min,
                    max: max,
                    strategic: strategic,
                    actual: actual,
                    isOver: isOver,
                    isUnder: isUnder,
                  )
                : _SimpleBar(actual: actual, color: actualColor),
          ],
        ),
      ),
    );
  }
}

class _MandateNumber extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MandateNumber({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Text(
        //   '${value.toStringAsFixed(1)}%',
        //   style: theme.textTheme.labelMedium?.copyWith(
        //     color: color,
        //     fontSize: 12,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
      ],
    );
  }
}

class _ComplianceBadge extends StatelessWidget {
  final bool isOver;
  final bool isUnder;
  final bool hasMandateData;
  final double diff;

  const _ComplianceBadge({
    required this.diff,
    required this.isOver,
    required this.isUnder,
    required this.hasMandateData,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMandateData) return const SizedBox.shrink();

    final Color bg;
    final Color fg;
    final String label;
    final IconData icon;

    if (isOver) {
      bg = _MandateColors.breach.withAlpha(60);
      fg = _MandateColors.breach;
      label = '${diff.toStringAsFixed(1)} % above max';
      icon = Icons.arrow_upward_rounded;
    } else if (isUnder) {
      bg = _MandateColors.underColor.withAlpha(20);
      fg = _MandateColors.underColor;
      label = '${diff.toStringAsFixed(1)} % below min';
      icon = Icons.arrow_downward_rounded;
    } else {
      bg = _MandateColors.within.withAlpha(60);
      fg = _MandateColors.within;
      label = 'OK';
      icon = Icons.check_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGauge extends StatelessWidget {
  final double min;
  final double max;
  final double strategic;
  final double actual;
  final bool isOver;
  final bool isUnder;

  const _RadialGauge({
    required this.min,
    required this.max,
    required this.strategic,
    required this.actual,
    required this.isOver,
    required this.isUnder,
  });

  // ── Geometry helpers ────────────────────────────────────────────────────────

  /// Maps a 0-100 % value onto the gauge's angular sweep.
  /// The gauge runs from 135 ° (bottom-left) clockwise 270 ° to 45 ° (bottom-right).
  static double _valueToDeg(double value) =>
      135.0 + (value.clamp(0, 100) / 100.0) * 270.0;

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Color actualColor = isOver
        ? _MandateColors.breach
        : isUnder
        ? _MandateColors.underColor
        : _MandateColors.actualWithin;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 180,
          child: SfRadialGauge(
            axes: [
              RadialAxis(
                minimum: 0,
                maximum: 100,
                showLabels: false,
                showTicks: false,
                radiusFactor: 0.88,

                // ── Base track ───────────────────────────────────────────────
                axisLineStyle: const AxisLineStyle(
                  thickness: 22,
                  cornerStyle: CornerStyle.bothCurve,
                  color: Color(0xFF2A2A2A),
                ),

                ranges: [
                  // ── Mandate band (min → max) ─────────────────────────────
                  GaugeRange(
                    startValue: min,
                    endValue: max,
                    color: _MandateColors.mandateRange,
                    startWidth: 22,
                    endWidth: 22,
                  ),

                  // // ── Filled progress inside band (min → actual), within only
                  // if (!isOver && !isUnder)
                  //   GaugeRange(
                  //     startValue: min,
                  //     endValue: actual,
                  //     color: _MandateColors.actualWithin.withOpacity(0.22),
                  //     startWidth: 14,
                  //     endWidth: 14,
                  //   ),
                ],

                pointers: [
                  // ── Min boundary tick ────────────────────────────────────
                  MarkerPointer(
                    value: min,
                    markerType: MarkerType.invertedTriangle,
                    // Rectangle oriented radially: narrow width, taller height
                    // so it straddles the arc like a tick mark.
                    markerWidth: 5,
                    markerHeight: 30,
                    color: _MandateColors.minMaxTick,
                    enableAnimation: true,
                  ),

                  // ── Max boundary tick ────────────────────────────────────
                  MarkerPointer(
                    value: max,
                    markerType: MarkerType.invertedTriangle,
                    markerWidth: 5,
                    markerHeight: 30,
                    color: _MandateColors.minMaxTick,
                    enableAnimation: true,
                  ),

                  // ── Strategic target — diamond on outer edge ─────────────
                  MarkerPointer(
                    value: strategic,
                    markerType: MarkerType.triangle,
                    markerWidth: 4,
                    markerHeight: 25,

                    // Offset outward so the diamond sits just outside the arc.
                    offsetUnit: GaugeSizeUnit.logicalPixel,
                    color: _MandateColors.strategic,
                    enableAnimation: true,
                  ),

                  // ── Actual allocation needle ─────────────────────────────
                  NeedlePointer(
                    value: actual,
                    enableAnimation: true,
                    animationDuration: 800,
                    animationType: AnimationType.ease,

                    needleLength: 0.75,
                    needleStartWidth: 1,
                    needleEndWidth: 5,
                    needleColor: actualColor,

                    tailStyle: const TailStyle(
                      color: Color(0xFF444444),
                      width: 5,
                      length: 0.22,
                    ),

                    knobStyle: KnobStyle(
                      color: actualColor,
                      borderWidth: 0,
                      sizeUnit: GaugeSizeUnit.factor,
                      knobRadius: 0.07,
                    ),
                  ),
                ],

                annotations: [
                  // ── Min label ─────────────────────────────────────────────
                  GaugeAnnotation(
                    angle: _valueToDeg(min),
                    positionFactor: 1.2,
                    widget: _ArcTickLabel(
                      value: min,
                      color: _MandateColors.minMaxTick,
                    ),
                  ),

                  // ── Max label ─────────────────────────────────────────────
                  GaugeAnnotation(
                    angle: _valueToDeg(max),
                    positionFactor: 1.2,
                    widget: _ArcTickLabel(
                      value: max,
                      color: _MandateColors.minMaxTick,
                    ),
                  ),

                  // ── Strategic target label ────────────────────────────────
                  GaugeAnnotation(
                    angle: _valueToDeg(strategic),
                    positionFactor: 1.2,
                    widget: _ArcTickLabel(
                      prefix: 'Target',
                      value: strategic,
                      color: _MandateColors.strategic,
                      bold: true,
                    ),
                  ),

                  // // ── Actual value callout — tracks needle angle ────────────
                  // GaugeAnnotation(
                  //   angle: _valueToDeg(actual),
                  //   positionFactor: 1.2, // inside the arc, near the knob
                  //   widget: _ActualCallout(
                  //     value: actual,
                  //     color: actualColor,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),

        // ── Below-gauge summary row ──────────────────────────────────────────
        Transform.translate(
          offset: const Offset(0, -25),
          child: Column(
            children: [
              Text(
                '${actual.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: actualColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (actual > strategic)
              ? '${(actual - strategic).toStringAsFixed(1)}% above target'
              : '${(strategic - actual).toStringAsFixed(1)}% below target',
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: actualColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        // ── Min / Target / Max KPI strip ─────────────────────────────────────
        _GaugeKpiStrip(
          min: min,
          strategic: strategic,
          max: max,
          actualColor: actualColor,
        ),

      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small label rendered by GaugeAnnotation at each tick position
// ─────────────────────────────────────────────────────────────────────────────

class _ArcTickLabel extends StatelessWidget {
  final String? prefix;
  final double value;
  final Color color;
  final bool bold;

  const _ArcTickLabel({
    required this.value,
    required this.color,
    this.prefix,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null)
          Text(
            prefix!,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.7),
            ),
          ),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: bold ? 10 : 9,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact pill shown *inside* the arc, tracking the needle position
// ─────────────────────────────────────────────────────────────────────────────

class _ActualCallout extends StatelessWidget {
  final double value;
  final Color color;

  const _ActualCallout({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        '${value.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ArcLabel extends StatelessWidget {
  final String label;
  final double value;

  const _ArcLabel(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${value.toStringAsFixed(0)}%',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
    );
  }
}

class _GaugeLabel extends StatelessWidget {
  final String title;
  final double value;

  const _GaugeLabel(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[400],
          ),
        ),
        Text(
          value.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// 3-column KPI strip: Min | Target | Max
// ─────────────────────────────────────────────────────────────────────────────

class _GaugeKpiStrip extends StatelessWidget {
  final double min;
  final double strategic;
  final double max;
  final Color actualColor;

  const _GaugeKpiStrip({
    required this.min,
    required this.strategic,
    required this.max,
    required this.actualColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        children: [
          _KpiCell(
            bg: actualColor,
            label: 'Min',
            value: '${min.toStringAsFixed(0)}%',
            valueColor: _MandateColors.minMaxTick,
            sublabel: 'floor',
            border: Border(
              top: BorderSide(color: _MandateColors.minMaxTick, width: 2),
            ),
          ),
          // VerticalDivider(
          //   width: 1,
          //   thickness: 0.5,
          //   color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          // ),
          _KpiCell(
            bg: actualColor,
            label: 'Target',
            value: '${strategic.toStringAsFixed(0)}%',
            valueColor: _MandateColors.strategic,
            sublabel: 'strategic',
            border: Border(
              top: BorderSide(color: _MandateColors.strategic, width: 2),
            ),
          ),
          // VerticalDivider(
          //   width: 1,
          //   thickness: 0.5,
          //   color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          // ),
          _KpiCell(
            bg: actualColor,
            label: 'Max',
            value: '${max.toStringAsFixed(0)}%',
            valueColor: _MandateColors.minMaxTick,
            sublabel: 'ceiling',
            border: Border(
              top: BorderSide(color: _MandateColors.minMaxTick, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String sublabel;
  final Border border;
  final Color bg;

  const _KpiCell({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sublabel,
    required this.border,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: bg.withAlpha(0),
          border: border,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4),
           
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            // Text(
            //   sublabel,
            //   style: TextStyle(
            //     fontSize: 9,
            //     color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _MandateBar extends StatelessWidget {
  final double min;
  final double max;
  final double strategic;
  final double actual;
  final bool isOver;
  final bool isUnder;

  static const double _scale = 100.0;

  const _MandateBar({
    required this.min,
    required this.max,
    required this.strategic,
    required this.actual,
    required this.isOver,
    required this.isUnder,
  });

  @override
  Widget build(BuildContext context) {
    final actualColor = isOver
        ? _MandateColors.breach
        : isUnder
        ? _MandateColors.underColor
        : _MandateColors.actualWithin;

    return SizedBox(
      height: 36,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          double pct(double v) => (v.clamp(0, 100) / _scale) * barWidth;

          final mandateLeft = pct(min);
          final mandateWidth = (pct(max) - pct(min)).clamp(0.0, barWidth);
          final strategicX = pct(strategic);
          final actualX = pct(actual);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: actualColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Mandate range
              Positioned(
                top: 12,
                left: mandateLeft,
                width: mandateWidth,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: _MandateColors.mandateRange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Strategic line
              Positioned(
                top: 6,
                left: strategicX - 1,
                child: Container(
                  width: 2,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _MandateColors.strategic,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // // Min tick
              Positioned(
                top: 22,
                left: mandateLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    '${min.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: actualColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Max tick
              Positioned(
                top: 22,
                left: (pct(max) - 16).clamp(0, barWidth - 20),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    '${max.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: actualColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // // Strategic tick
              // Positioned(
              //   top: 22, left: (strategicX - 8).clamp(0, barWidth - 24),
              //   child: Padding(
              //         padding: const EdgeInsets.only(top: 2.0),
              //     child: Text('${strategic.toStringAsFixed(0)}%',
              //         style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 33, 66, 32), fontWeight: FontWeight.w600)),
              //   ),
              // ),
              // Actual dot
              Positioned(
                top: 7,
                left: actualX - 9,
                child: _ActualDot(
                  color: actualColor,
                  isOver: isOver,
                  isUnder: isUnder,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActualDot extends StatefulWidget {
  final Color color;
  final bool isOver;
  final bool isUnder;

  const _ActualDot({
    required this.color,
    required this.isOver,
    required this.isUnder,
  });

  @override
  State<_ActualDot> createState() => _ActualDotState();
}

class _ActualDotState extends State<_ActualDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.6,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isOver || widget.isUnder) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_ActualDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isOver || widget.isUnder) && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isOver && !widget.isUnder) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double dotSize = 18;

    if (!widget.isOver && !widget.isUnder) {
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => SizedBox(
        width: dotSize,
        height: dotSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scale.value,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: dotSize - 4,
              height: dotSize - 4,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleBar extends StatelessWidget {
  final double actual;
  final Color color;

  const _SimpleBar({required this.actual, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Stack(
        children: [
          Container(
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          FractionallySizedBox(
            widthFactor: (actual / 100).clamp(0, 1),
            child: Container(
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

abstract class _MandateColors {
  static const Color mandateRange = Color.fromARGB(
    255,
    30,
    64,
    92,
  ); // Azure band
  static const Color strategic = Color(0xFFD81B60); // Amber diamond
  static const Color minMaxTick = Color(0xFF378ADD); // Blue boundary ticks
  static const Color actualWithin = Color(0xFF1D9E75); // Green
  static const Color breach = Color(0xFFE24B4A); // Red
  static const Color underColor = Color.fromARGB(255, 255, 217, 1); // Amber
  static const Color within = Color(0xFF1D9E75); // Green (alias)
}

String _formatCurrency(double value) {
  if (value >= 1000000) return '€${(value / 1000000).toStringAsFixed(2)}M';
  if (value >= 1000) return '€${(value / 1000).toStringAsFixed(1)}K';
  return '€${value.toStringAsFixed(2)}';
}
