import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StepperButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPositive;
  final bool isAccent;
  final double? width;
  final double height;

  const StepperButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPositive = true,
    this.isAccent = false,
    this.width,
    this.height = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    if (isAccent) {
      bgColor = AppTheme.neonGreen.withAlpha(35);
      textColor = AppTheme.neonGreen;
      borderColor = AppTheme.neonGreen.withAlpha(120);
    } else if (isPositive) {
      bgColor = AppTheme.bgCard;
      textColor = const Color(0xFF4ADE80);
      borderColor = AppTheme.borderSubtle;
    } else {
      bgColor = AppTheme.bgCard;
      textColor = const Color(0xFFF87171);
      borderColor = AppTheme.borderSubtle;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppTheme.neonGreen.withAlpha(60),
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
