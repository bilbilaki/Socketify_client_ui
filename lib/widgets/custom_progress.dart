import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A reusable linear progress indicator with optional title and description.
class CustomLinearProgress extends StatelessWidget {
  final String? title;
  final String? description;
  final double value;
  final double minHeight;
  final Color? backgroundColor;
  final Color? valueColor;
  final bool showPercentage;
  final TextStyle? percentageStyle;

  const CustomLinearProgress({
    super.key,
    this.title,
    this.description,
    required this.value,
    this.minHeight = 8,
    this.backgroundColor,
    this.valueColor,
    this.showPercentage = true,
    this.percentageStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final valColor = valueColor ?? colorScheme.primary;
    final percentage = (value * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 2.0),
            child: Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
            child: Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: minHeight,
                  backgroundColor: bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(valColor),
                ),
              ),
            ),
            if (showPercentage)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  '$percentage%',
                  style:
                      percentageStyle ??
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valColor,
                      ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A reusable circular progress indicator with optional title and description.
class CustomCircularProgress extends StatelessWidget {
  final String? title;
  final String? description;
  final double value;
  final double size;
  final Color? backgroundColor;
  final Color? valueColor;
  final bool showPercentage;
  final double strokeWidth;
  final TextStyle? percentageStyle;

  const CustomCircularProgress({
    super.key,
    this.title,
    this.description,
    required this.value,
    this.size = 100,
    this.backgroundColor,
    this.valueColor,
    this.showPercentage = true,
    this.strokeWidth = 8,
    this.percentageStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final valColor = valueColor ?? colorScheme.primary;
    final percentage = (value * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: bgColor,
                valueColor: AlwaysStoppedAnimation<Color>(valColor),
              ),
              if (showPercentage)
                Text(
                  '$percentage%',
                  style:
                      percentageStyle ??
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valColor,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// An indeterminate circular progress indicator (loading spinner).
class CustomLoadingSpinner extends StatelessWidget {
  final String? title;
  final String? description;
  final double size;
  final Color? valueColor;
  final double strokeWidth;

  const CustomLoadingSpinner({
    super.key,
    this.title,
    this.description,
    this.size = 60,
    this.valueColor,
    this.strokeWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valColor = valueColor ?? colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(valColor),
          ),
        ),
      ],
    );
  }
}

/// A stepped progress indicator showing progress through multiple steps.
class CustomSteppedProgress extends StatelessWidget {
  final String? title;
  final String? description;
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final Color? completedColor;
  final Color? activeColor;
  final Color? pendingColor;
  final double stepSize;
  final bool showLabels;

  const CustomSteppedProgress({
    super.key,
    this.title,
    this.description,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.completedColor,
    this.activeColor,
    this.pendingColor,
    this.stepSize = 40,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = completedColor ?? colorScheme.primary;
    final active = activeColor ?? colorScheme.secondary;
    final pending = pendingColor ?? colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 2.0),
            child: Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 2.0),
            child: Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Column(
          children: [
            // Steps Row
            SizedBox(
              height: stepSize,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(totalSteps, (index) {
                  final isCompleted = index < currentStep - 1;
                  final isActive = index == currentStep - 1;
                  // ignore: unused_local_variable
                  final isPending = index > currentStep - 1;

                  return Expanded(
                    child: Row(
                      children: [
                        // Step Circle
                        Container(
                          width: stepSize,
                          height: stepSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? completed
                                : isActive
                                ? active
                                : pending,
                            border: isActive
                                ? Border.all(color: active, width: 3)
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    color: colorScheme.onPrimary,
                                    size: stepSize * 0.5,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isActive
                                          ? colorScheme.onSecondary
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: stepSize * 0.4,
                                    ),
                                  ),
                          ),
                        ),
                        // Connector Line
                        if (index < totalSteps - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              color: isCompleted ? completed : pending,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            // Labels
            if (showLabels &&
                stepLabels != null &&
                stepLabels!.length == totalSteps)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: stepLabels!.map((label) {
                    return SizedBox(
                      width: stepSize + 8,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A segmented progress bar showing multiple sections with different progress values.
class CustomSegmentedProgress extends StatelessWidget {
  final String? title;
  final String? description;
  final List<ProgressSegment> segments;
  final double height;
  final bool showLabels;
  final TextStyle? labelStyle;

  const CustomSegmentedProgress({
    super.key,
    this.title,
    this.description,
    required this.segments,
    this.height = 24,
    this.showLabels = true,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = segments.fold<double>(0, (sum, seg) => sum + seg.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 2.0),
            child: Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
            child: Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: segments.map((segment) {
              final percentage = total > 0 ? segment.value / total : 0;
              return Expanded(
                flex: (segment.value * 100).toInt(),
                child: Tooltip(
                  message:
                      '${segment.label}: ${(percentage * 100).toStringAsFixed(1)}%',
                  child: Container(
                    height: height,
                    color: segment.color ?? colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: segments.map((segment) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: segment.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      segment.label,
                      style:
                          labelStyle ?? Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/// Model for segmented progress segments
class ProgressSegment {
  final String label;
  final double value;
  final Color? color;

  ProgressSegment({required this.label, required this.value, this.color});
}

/// An animated wave progress indicator.
class CustomWaveProgress extends StatefulWidget {
  final String? title;
  final String? description;
  final double value;
  final double size;
  final Color? waveColor;
  final Color? backgroundColor;
  final bool showPercentage;

  const CustomWaveProgress({
    super.key,
    this.title,
    this.description,
    required this.value,
    this.size = 120,
    this.waveColor,
    this.backgroundColor,
    this.showPercentage = true,
  });

  @override
  State<CustomWaveProgress> createState() => _CustomWaveProgressState();
}

class _CustomWaveProgressState extends State<CustomWaveProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final waveCol = widget.waveColor ?? colorScheme.primary;
    final bgCol = widget.backgroundColor ?? colorScheme.surfaceContainerHighest;
    final percentage = (widget.value * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              widget.title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        if (widget.description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              widget.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: bgCol),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WavePainter(
                      waveValue: widget.value,
                      waveColor: waveCol,
                      progress: _controller.value,
                    ),
                    size: Size(widget.size, widget.size),
                  );
                },
              ),
              if (widget.showPercentage)
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: waveCol,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final double waveValue;
  final Color waveColor;
  final double progress;

  _WavePainter({
    required this.waveValue,
    required this.waveColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final waveHeight = radius * 0.2;

    final path = Path();
    path.moveTo(0, center.dy + (waveHeight * (1 - waveValue)));

    for (double x = 0; x <= size.width; x++) {
      final waveOffset = ((x / size.width - progress) * 360) % 360;
      final angle = waveOffset * 3.141592653589793 / 180;
      final y =
          center.dy +
          (waveHeight * (1 - waveValue)) +
          (waveHeight *
              0.5 *
              (1 - (waveValue * 2).clamp(0, 1)) *
              math.sin(angle));
      path.lineTo(x.toDouble(), y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}
