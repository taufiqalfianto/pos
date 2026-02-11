import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:pos/core/util/app_style.dart';

class ToastHelper {
  static void showSuccess(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      color: AppColors.error,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      color: AppColors.primary,
    );
  }

  static void _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
  }) {
    DelightToastBar(
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
      snackbarDuration: const Duration(seconds: 3),
      builder: (context) => ToastCard(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
    ).show(context);
  }
}
