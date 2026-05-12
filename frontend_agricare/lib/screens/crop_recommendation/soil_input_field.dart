// File: lib/screens/crop_recommendation/soil_input_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SoilInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String suffix;
  final double? minValue;
  final double? maxValue;
  final String? rangeLabel;
  final String? description;
  final bool readOnly; // ← NEW

  const SoilInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.suffix,
    this.minValue,
    this.maxValue,
    this.rangeLabel,
    this.description,
    this.readOnly = false, // ← default false — no breaking change
  });

  @override
  State<SoilInputField> createState() => _SoilInputFieldState();
}

class _SoilInputFieldState extends State<SoilInputField>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _borderCtrl;
  late Animation<double> _borderAnim;

  static const _dark     = Color(0xFF1A2F0E);
  static const _mid      = Color(0xFF4A7C2C);
  static const _border   = Color(0xFFDFEDD3);
  static const _surface  = Color(0xFFEDF4E5);
  static const _error    = Color(0xFFDC2626);
  static const _errorBg  = Color(0xFFFEF2F2);

  // Pakistan lock colours
  static const _pkGreen  = Color(0xFF01411C);
  static const _pkBg     = Color(0xFFE8F5E3);
  static const _pkBorder = Color(0xFF8FBD7A);

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _borderAnim =
        CurvedAnimation(parent: _borderCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _borderCtrl.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    // Skip validation when read-only — value is guaranteed valid
    if (widget.readOnly) return null;
    if (value == null || value.trim().isEmpty) return 'Required';
    final num = double.tryParse(value);
    if (num == null) return 'Enter a valid number';
    if (widget.minValue != null && num < widget.minValue!) {
      return 'Min value is ${widget.minValue}${widget.suffix.isNotEmpty ? ' ${widget.suffix}' : ''}';
    }
    if (widget.maxValue != null && num > widget.maxValue!) {
      return 'Max value is ${widget.maxValue}${widget.suffix.isNotEmpty ? ' ${widget.suffix}' : ''}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.readOnly;

    return FormField<String>(
      validator: (_) => _validate(widget.controller.text),
      builder: (state) {
        final hasError = state.hasError;

        // ── Locked (read-only) appearance ──────────────────────────────────
        if (isLocked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row
              Row(
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _pkGreen,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _pkBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _pkBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 9, color: _pkGreen),
                        SizedBox(width: 3),
                        Text(
                          'Pakistan default',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _pkGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),

              // Locked input box
              Container(
                decoration: BoxDecoration(
                  color: _pkBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _pkBorder, width: 1.5),
                ),
                child: TextFormField(
                  controller: widget.controller,
                  readOnly: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _pkGreen,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    prefixIcon: Container(
                      width: 46,
                      alignment: Alignment.center,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _pkGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(widget.icon, size: 17, color: _pkGreen),
                      ),
                    ),
                    suffixIcon: widget.suffix.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _pkGreen.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.suffix,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _pkGreen,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          )
                        : null,
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 15),
                  ),
                  validator: _validate,
                ),
              ),

              // Description
              if (widget.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.description!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _pkGreen,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          );
        }

        // ── Normal (editable) appearance ───────────────────────────────────
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                    letterSpacing: -0.1,
                  ),
                ),
                const Spacer(),
                if (widget.rangeLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasError ? _errorBg : _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasError
                            ? _error.withOpacity(0.3)
                            : _border,
                      ),
                    ),
                    child: Text(
                      'Range: ${widget.rangeLabel}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasError
                            ? _error
                            : const Color(0xFF5A7A45),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),

            // Input box
            AnimatedBuilder(
              animation: _borderAnim,
              builder: (context, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: hasError ? _errorBg : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasError
                        ? _error.withOpacity(0.5)
                        : _isFocused
                            ? _mid
                            : _border,
                    width: _isFocused || hasError ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasError
                          ? _error.withOpacity(0.07)
                          : _isFocused
                              ? _mid.withOpacity(0.1)
                              : Colors.black.withOpacity(0.03),
                      blurRadius: _isFocused ? 12 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Focus(
                  onFocusChange: (focused) {
                    setState(() => _isFocused = focused);
                    if (focused) {
                      _borderCtrl.forward();
                    } else {
                      _borderCtrl.reverse();
                      state.validate();
                    }
                  },
                  child: TextFormField(
                    controller: widget.controller,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      letterSpacing: -0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFBBBBBB),
                      ),
                      prefixIcon: Container(
                        width: 46,
                        alignment: Alignment.center,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: hasError
                                ? _error.withOpacity(0.1)
                                : _isFocused
                                    ? _mid.withOpacity(0.1)
                                    : _surface,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 17,
                            color: hasError
                                ? _error
                                : _isFocused
                                    ? _mid
                                    : const Color(0xFF8FAF7A),
                          ),
                        ),
                      ),
                      suffixIcon: widget.suffix.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: hasError
                                      ? _error.withOpacity(0.08)
                                      : _surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.suffix,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: hasError
                                        ? _error
                                        : const Color(0xFF5A7A45),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            )
                          : null,
                      suffixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 15),
                    ),
                    validator: _validate,
                    onChanged: (_) {
                      if (state.hasError) state.validate();
                    },
                  ),
                ),
              ),
            ),

            // Error message
            if (hasError) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.error_rounded, size: 13, color: _error),
                  const SizedBox(width: 5),
                  Text(
                    state.errorText!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _error,
                    ),
                  ),
                ],
              ),
            ],

            // Description hint
            if (widget.description != null && !hasError) ...[
              const SizedBox(height: 4),
              Text(
                widget.description!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9DB88A),
                  height: 1.4,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}