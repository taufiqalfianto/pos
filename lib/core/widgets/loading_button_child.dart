import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingButtonChild extends StatelessWidget {
  const LoadingButtonChild({
    super.key,
    required this.isLoading,
    required this.label,
    this.icon,
    this.textStyle,
    this.progressColor,
  });

  final bool isLoading;
  final String label;
  final IconData? icon;
  final TextStyle? textStyle;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 22.w,
        height: 22.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.4.w,
          valueColor: AlwaysStoppedAnimation<Color>(
            progressColor ?? Colors.white,
          ),
        ),
      );
    }

    final text = Text(label, style: textStyle);
    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20.r),
        SizedBox(width: 8.w),
        text,
      ],
    );
  }
}
