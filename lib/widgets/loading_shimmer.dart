import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// 骨架屏占位
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    );
  }
}
