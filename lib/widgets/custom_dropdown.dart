import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final bool isRequired;
  final IconData? prefixIcon;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const CustomDropdown({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.items,
    this.isRequired = false,
    this.prefixIcon,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.neutralTextPrimary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dangerRedPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Dropdown field
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator:
              validator ??
              (isRequired
                  ? (value) => value == null ? '$label is required' : null
                  : null),
          decoration: InputDecoration(
            hintText: hint ?? 'Select $label',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.neutralTextPlaceholder,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.neutralTextMuted)
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutralBorderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.neutralBorderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryPurpleDeep,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.dangerRedPrimary),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.dangerRedPrimary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutralTextPrimary,
          ),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.neutralTextMuted,
          ),
        ),
      ],
    );
  }
}
