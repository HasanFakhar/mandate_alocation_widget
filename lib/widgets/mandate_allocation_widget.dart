import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

      final withinCount = allClasses.where((c) => ctrl.isWithinMandate(c)).length;
      final breachCount = allClasses.length - withinCount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WidgetHeader(
            totalValue: ctrl.totalPortfolioValue,
            assetClassCount: allClasses.length,
            withinCount: withinCount,
            breachCount: breachCount,
          ),
          const SizedBox(height: 16),
          const _Legend(),
          const SizedBox(height: 12),
          ...allClasses.map((assetClass) => _AllocationRow(
                assetClass: assetClass,
                actual: ctrl.actualAllocation(assetClass),
                marketValue: ctrl.marketValue(assetClass),
                mandate: ctrl.mandateFor(assetClass),
              )),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _WidgetHeader extends StatelessWidget {
  final double totalValue;
  final int assetClassCount;
  final int withinCount;
  final int breachCount;

  const _WidgetHeader({
    required this.totalValue,
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
                'Mandate Allocation',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
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
          const SizedBox(height: 12),
          Row(
            children: [
              _HeaderStat(label: 'Total value', value: _formatCurrency(totalValue)),
              const SizedBox(width: 24),
              _HeaderStat(label: 'Asset classes', value: '$assetClassCount'),
              const SizedBox(width: 24),
              _HeaderStat(
                label: 'Within mandate',
                value: '$withinCount / $assetClassCount',
                valueColor: withinCount == assetClassCount
                    ? _MandateColors.within
                    : _MandateColors.breach,
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
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.withAlpha(30),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: const [
          _LegendItem(color: _MandateColors.mandateRange, label: 'Allowed range',    shape: _LegendShape.rect),
          _LegendItem(color: _MandateColors.strategic,    label: 'Strategic target', shape: _LegendShape.line),
          _LegendItem(color: _MandateColors.actualWithin, label: 'Actual (within)',  shape: _LegendShape.circle),
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
      ),
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
          width: 16, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        );
      case _LegendShape.line:
        indicator = SizedBox(
          width: 16, height: 10,
          child: Center(child: Container(width: 2, height: 10, color: color)),
        );
      case _LegendShape.circle:
        indicator = Container(
          width: 10, height: 10,
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
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

    final double min       = mandate?.min ?? 0;
    final double max       = mandate?.max ?? 100;
    final double strategic = mandate?.strategic ?? ((min + max) / 2);
    final bool hasMandateData = mandate != null;
    final bool isOver     = hasMandateData && actual > max;
    final bool isUnder    = hasMandateData && actual < min;
    final bool isBreach   = isOver || isUnder;

  final Color cardBackground = isOver
    ? _MandateColors.breach.withAlpha(30)
    : isUnder
        ? _MandateColors.underBreach.withAlpha(30)
        : hasMandateData
            ? _MandateColors.within.withAlpha(30)
            : theme.colorScheme.outlineVariant;

final Color cardBorderColor = isOver
    ? _MandateColors.breach
    : isUnder
        ? _MandateColors.underColor
        : hasMandateData
            ? _MandateColors.within
            : theme.colorScheme.outlineVariant;

final Color actualColor = isOver
    ? _MandateColors.overBreach
    : isUnder
        ? _MandateColors.underBreach
        : _MandateColors.actualWithin;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          )
        ] ,
        
        color: cardBackground,
        border: Border.all(color: cardBorderColor, width: isBreach ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: name / market value / numbers / badge ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + market value
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assetClass,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(marketValue),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mandate numbers
                if (hasMandateData) ...[
                  _MandateNumber(label: 'Min',value: min,color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  _MandateNumber(label: 'Strategic', value: strategic, color: _MandateColors.strategic),
                  const SizedBox(width: 10),
                  _MandateNumber(label: 'Max',value: max,color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                ],

                _MandateNumber(label: 'Actual', value: actual, color: actualColor, bold: true),
                const SizedBox(width: 10),

                _ComplianceBadge(
                  isOver: isOver,
                  isUnder: isUnder,
                  hasMandateData: hasMandateData,
                ),
              ],
            ),

            const SizedBox(height: 10),

            hasMandateData
                ? _MandateBar(
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
  final bool bold;

  const _MandateNumber({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


class _ComplianceBadge extends StatelessWidget {
  final bool isOver;
  final bool isUnder;
  final bool hasMandateData;

  const _ComplianceBadge({
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
      label = 'Over';
      icon = Icons.arrow_upward_rounded;
    } else if (isUnder) {
      bg = _MandateColors.underColor.withAlpha(20);
      fg = _MandateColors.underColor;
      label = 'Under';
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
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
    required this.isOver ,
    required this.isUnder,
  });

  @override
  Widget build(BuildContext context) {
    final actualColor =
        isOver ? _MandateColors.breach
        : isUnder ? _MandateColors.underColor
        : _MandateColors.actualWithin;

    return SizedBox(
      height: 36,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          double pct(double v) => (v.clamp(0, 100) / _scale) * barWidth;

          final mandateLeft  = pct(min);
          final mandateWidth = (pct(max) - pct(min)).clamp(0.0, barWidth);
          final strategicX   = pct(strategic);
          final actualX      = pct(actual);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 12, left: 0, right: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(220),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Mandate range
              Positioned(
                top: 12, left: mandateLeft, width: mandateWidth,
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
                top: 6, left: strategicX - 1,
                child: Container(
                  width: 2, height: 20,
                  decoration: BoxDecoration(
                    color: _MandateColors.strategic,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // // Min tick
              // Positioned(
              //   top: 22, left: mandateLeft,
              //   child: Padding(
              //     padding: const EdgeInsets.only(top: 2.0),
              //     child: Text('${min.toStringAsFixed(0)}%',
              //         style: TextStyle(fontSize: 10, color:Colors.black, fontWeight: FontWeight.w500)),
              //   ),
              // ),
              // // Max tick
              // Positioned(
              //   top: 22, left: (pct(max) - 16).clamp(0, barWidth - 20),
              //   child: Padding(
              //     padding: const EdgeInsets.only(top: 2.0),
              //     child: Text('${max.toStringAsFixed(0)}%',
              //         style: TextStyle(fontSize:10, color: Colors.black, fontWeight: FontWeight.w500)),
              //   ),
              // ),
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
                top: 7, left: actualX - 9,
                child: _ActualDot(color: actualColor, isOver: isOver, isUnder: isUnder),
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

  const _ActualDot({required this.color, required this.isOver, required this.isUnder});

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
    _scale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
        width: dotSize, height: dotSize,
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
        width: dotSize, height: dotSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scale.value,
              child: Container(
                width: dotSize, height: dotSize,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: dotSize - 4, height: dotSize - 4,
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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}



abstract class _MandateColors {
  static const Color mandateRange  = Color(0xFFB3D4F5);
  static const Color strategic     = Color(0xFF3B6D11);
  static const Color actualWithin  = Color(0xFF1E7E4A);
  static const Color breach        = Color(0xFFD93025);
  static const Color underColor    = Color(0xFFE8891A);
 static const Color overBreach    = Color.fromARGB(255, 83, 6, 0); // red
  static const Color underBreach   = Color.fromARGB(255, 212, 54, 43); // yellow
  static const Color within        = Color(0xFF1E7E4A);
}


String _formatCurrency(double value) {
  if (value >= 1000000) return '€${(value / 1000000).toStringAsFixed(2)}M';
  if (value >= 1000) return '€${(value / 1000).toStringAsFixed(1)}K';
  return '€${value.toStringAsFixed(2)}';
}