import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/theme/app_theme.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/loading_button_child.dart';

/// Tombol aksi utama (CTA) dengan ukuran kanonik aplikasi: tinggi 60 (portrait)
/// · 52 (lanskap ponsel & tablet), lebar penuh, radius & tipografi dari theme.
///
/// Pakai widget ini untuk CTA halaman supaya ukuran tombol tidak lagi
/// ditentukan per layar.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  /// Tinggi kanonik CTA per breakpoint.
  static double heightFor(BuildContext context) =>
      ResponsiveLayout.adaptiveValue(
        context,
        portrait: 60,
        landscape: 52,
        tablet: 52,
      ).h;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: heightFor(context),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: LoadingButtonChild(
          isLoading: isLoading,
          label: label,
          icon: icon,
          textStyle: AppTheme.buttonTextStyle(
            Theme.of(context).textTheme,
          ).copyWith(color: AppColors.background),
        ),
      ),
    );
  }
}
