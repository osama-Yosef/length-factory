import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String initial;
  final double radius;
  final Color color;

  const UserAvatar({
    super.key,
    required this.initial,
    this.radius = 22,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: radius * 0.8),
      ),
    );
  }
}
