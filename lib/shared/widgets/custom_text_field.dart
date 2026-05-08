import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../theme/modern_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool useGlassmorphism;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.suffixIcon,
    this.prefixIcon,
    this.useGlassmorphism = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: widget.useGlassmorphism
          ? BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? AppColors.primary
                    : isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.2),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
            )
          : null,
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() => _isFocused = hasFocus);
        },
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          validator: widget.validator,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: isDark ? Colors.white : AppColors.text,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            border: widget.useGlassmorphism
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
            enabledBorder: widget.useGlassmorphism
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
            focusedBorder: widget.useGlassmorphism
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
            errorBorder: widget.useGlassmorphism
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
            focusedErrorBorder: widget.useGlassmorphism
                ? InputBorder.none
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
            filled: !widget.useGlassmorphism,
            fillColor: widget.useGlassmorphism
                ? Colors.transparent
                : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
            suffixIcon: widget.suffixIcon != null
                ? AnimatedContainer(
                    duration: ModernTheme.microAnimationFast,
                    child: widget.suffixIcon,
                  )
                : null,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      (widget.prefixIcon as Icon).icon,
                      color: _isFocused
                          ? AppColors.primary
                          : isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.grey,
                      size: 20,
                    ),
                  )
                : null,
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: _isFocused
                  ? AppColors.primary
                  : isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.text.withValues(alpha: 0.6),
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
            ),
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : AppColors.text.withValues(alpha: 0.4),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.prefixIcon != null ? 8 : 16,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }
}
