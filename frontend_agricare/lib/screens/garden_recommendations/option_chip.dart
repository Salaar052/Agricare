// ============================================================
// option_chip.dart — Reusable Selection Chip Widget
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionChip extends StatelessWidget {
  final String value;
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionChip({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D6A4F)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D6A4F)
                : const Color(0xFFD8E8D4),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of option chips for a single category.
class OptionChipGroup extends StatelessWidget {
  final String label;
  final List<Map<String, String>> options;
  final String? selectedValue;
  final Function(String) onSelect;

  const OptionChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B4332),
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: options.map((opt) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: opt == options.last ? 0 : 10,
                  ),
                  child: OptionChip(
                    value: opt['value']!,
                    label: opt['label']!,
                    icon: opt['icon']!,
                    isSelected: selectedValue == opt['value'],
                    onTap: () => onSelect(opt['value']!),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}