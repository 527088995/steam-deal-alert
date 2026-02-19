import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// 高饱和主按钮
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const GradientButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF66C0F4), Color(0xFF4A9FD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
