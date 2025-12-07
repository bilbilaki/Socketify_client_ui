import 'package:flutter/material.dart';

/// A base wrapper to display a title and description above or beside an input widget.
class _InputWrapper extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  const _InputWrapper({
    this.title,
    this.description,
    required this.child,
    // ignore: unused_element_parameter
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (title == null && description == null) {
      return child;
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        child,
      ],
    );
  }
}

/// A reusable text input widget for String or Int values.
class CustomTextInput extends StatelessWidget {
  final String? title;
  final String? description;
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool isNumber;
  final TextEditingController? controller;
  final bool obscureText;
  final IconData? prefixIcon;

  const CustomTextInput({
    super.key,
    this.title,
    this.description,
    this.hintText,
    this.initialValue,
    this.onChanged,
    this.isNumber = false,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return _InputWrapper(
      title: title,
      description: description,
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        onChanged: onChanged,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
      ),
    );
  }
}

/// A reusable dropdown selector widget.
class CustomDropdown<T> extends StatelessWidget {
  final String? title;
  final String? description;
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T) itemLabelBuilder;
  final String? hintText;

  const CustomDropdown({
    super.key,
    this.title,
    this.description,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return _InputWrapper(
      title: title,
      description: description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            hint: hintText != null ? Text(hintText!) : null,
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabelBuilder(item)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

/// A reusable checkbox widget with title and description.
class CustomCheckbox extends StatelessWidget {
  final String? title;
  final String? description;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const CustomCheckbox({
    super.key,
    this.title,
    this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: title != null
          ? Text(title!, style: Theme.of(context).textTheme.titleMedium)
          : null,
      subtitle: description != null
          ? Text(description!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

/// A reusable switch widget with title and description.
class CustomSwitch extends StatelessWidget {
  final String? title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CustomSwitch({
    super.key,
    this.title,
    this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: title != null
          ? Text(title!, style: Theme.of(context).textTheme.titleMedium)
          : null,
      subtitle: description != null
          ? Text(description!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

/// A reusable slider widget with title, description, and value display.
class CustomSlider extends StatelessWidget {
  final String? title;
  final String? description;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String Function(double)? labelBuilder;

  const CustomSlider({
    super.key,
    this.title,
    this.description,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _InputWrapper(
      title: title,
      description: description,
      child: Row(
        children: [
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: labelBuilder != null
                  ? labelBuilder!(value)
                  : value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
          if (labelBuilder != null || true)
            Container(
              width: 50,
              alignment: Alignment.centerRight,
              child: Text(
                labelBuilder != null
                    ? labelBuilder!(value)
                    : value.toStringAsFixed(1),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
