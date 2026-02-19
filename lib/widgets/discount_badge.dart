import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DiscountBadge extends StatelessWidget {
  final int discount;
  final bool large;

  const DiscountBadge({super.key, required this.discount, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error ?? const Color(0xFFC54534);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: large ? 4 : 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '-$discount%',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: large ? 16 : 12,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
