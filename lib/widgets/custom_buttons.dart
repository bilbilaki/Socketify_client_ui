import 'package:flutter/material.dart';

/// A reusable elevated button with optional icon, title, description, and customization.
class CustomButton extends StatelessWidget {
  final String? title;
  final String? description;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    this.title,
    this.description,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primary;
    final fgColor = foregroundColor ?? colorScheme.onPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
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
        SizedBox(
          width: width,
          height: height ?? 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) Icon(icon, size: 20),
                      if (icon != null && title != null)
                        const SizedBox(width: 8),
                      if (title != null)
                        Text(title!, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// A reusable icon button with optional title, description, and tooltip.
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String? description;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double iconSize;
  final Color? backgroundColor;
  final bool isSelected;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.title,
    this.description,
    this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.iconSize = 24,
    this.backgroundColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        backgroundColor ??
        (isSelected ? colorScheme.primaryContainer : Colors.transparent);
    final fgColor =
        iconColor ??
        (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
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
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: IconButton(
            icon: Icon(icon, size: iconSize),
            color: fgColor,
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        ),
      ],
    );
  }
}

/// A reusable text button (flat button) with optional icon and description.
class CustomTextButton extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? textColor;
  final bool underline;
  final double fontSize;

  const CustomTextButton({
    super.key,
    required this.title,
    this.description,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.underline = false,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fgColor = textColor ?? colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: fgColor,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18),
              if (icon != null) const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  decoration: underline ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A reusable touchable/pressable button with visual feedback and ripple effect.
class CustomTouchableButton extends StatefulWidget {
  final String? title;
  final String? description;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? pressedColor;
  final double? width;
  final double? height;
  final bool enabled;

  const CustomTouchableButton({
    super.key,
    this.title,
    this.description,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.pressedColor,
    this.width,
    this.height,
    this.enabled = true,
  });

  @override
  State<CustomTouchableButton> createState() => _CustomTouchableButtonState();
}

class _CustomTouchableButtonState extends State<CustomTouchableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = widget.backgroundColor ?? colorScheme.primaryContainer;
    final pressedBgColor = widget.pressedColor ?? colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
            child: Text(
              widget.title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        if (widget.description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 2.0),
            child: Text(
              widget.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        GestureDetector(
          onTapDown: (_) {
            if (widget.enabled) {
              setState(() => _isPressed = true);
            }
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (widget.enabled) widget.onPressed?.call();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: widget.width,
            height: widget.height ?? 56,
            decoration: BoxDecoration(
              color: _isPressed ? pressedBgColor : bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null)
                    Icon(
                      widget.icon,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  if (widget.icon != null && widget.title != null)
                    const SizedBox(width: 12),
                  if (widget.title != null)
                    Text(
                      widget.title!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A reusable long-press button with visual feedback and haptic feedback on long press.
class CustomLongPressButton extends StatefulWidget {
  final String? title;
  final String? description;
  final VoidCallback? onLongPress;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? longPressColor;
  final Duration longPressDuration;
  final double? width;
  final double? height;
  final bool enabled;

  const CustomLongPressButton({
    super.key,
    this.title,
    this.description,
    required this.onLongPress,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.longPressColor,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.width,
    this.height,
    this.enabled = true,
  });

  @override
  State<CustomLongPressButton> createState() => _CustomLongPressButtonState();
}

class _CustomLongPressButtonState extends State<CustomLongPressButton> {
  bool _isLongPressed = false;
  // ignore: unused_field
  late DateTime _pressStartTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = widget.backgroundColor ?? colorScheme.secondaryContainer;
    final longPressBgColor = widget.longPressColor ?? colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
            child: Text(
              widget.title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        if (widget.description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 2.0),
            child: Text(
              widget.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        GestureDetector(
          onTapDown: (_) {
            if (widget.enabled) {
              _pressStartTime = DateTime.now();
            }
          },
          onTapUp: (_) {
            if (widget.enabled && !_isLongPressed) {
              widget.onPressed?.call();
            }
            setState(() => _isLongPressed = false);
          },
          onLongPressStart: (_) {
            if (widget.enabled) {
              setState(() => _isLongPressed = true);
            }
          },
          onLongPressEnd: (_) {
            if (widget.enabled && _isLongPressed) {
              widget.onLongPress?.call();
            }
            setState(() => _isLongPressed = false);
          },
          onLongPressCancel: () {
            setState(() => _isLongPressed = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.width,
            height: widget.height ?? 60,
            decoration: BoxDecoration(
              color: _isLongPressed ? longPressBgColor : bgColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null)
                        Icon(
                          widget.icon,
                          color: colorScheme.onSecondaryContainer,
                          size: 24,
                        ),
                      if (widget.icon != null && widget.title != null)
                        const SizedBox(width: 12),
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLongPressed)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_isLongPressed)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 2.0),
            child: Text(
              '(Long press detected)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// A reusable outline button with optional icon and customization.
class CustomOutlineButton extends StatelessWidget {
  final String? title;
  final String? description;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;

  const CustomOutlineButton({
    super.key,
    this.title,
    this.description,
    required this.onPressed,
    this.icon,
    this.borderColor,
    this.foregroundColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderCol = borderColor ?? colorScheme.primary;
    final fgCol = foregroundColor ?? colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
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
        SizedBox(
          width: width,
          height: height ?? 48,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: fgCol,
              side: BorderSide(color: borderCol, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, size: 20),
                if (icon != null && title != null) const SizedBox(width: 8),
                if (title != null) Text(title!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
