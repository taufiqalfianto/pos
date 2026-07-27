import 'package:flutter/material.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';

class ModernDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final Color confirmColor;
  final IconData icon;

  const ModernDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    this.confirmColor = AppColors.primary,
    required this.icon,
  });

  static void show({
    required BuildContext context,
    required String title,
    required Widget content,
    String confirmText = 'KONFIRMASI',
    String cancelText = 'BATAL',
    required VoidCallback onConfirm,
    Color confirmColor = AppColors.primary,
    IconData icon = Icons.info_outline_rounded,
  }) {
    showDialog(
      context: context,
      builder: (context) => ModernDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);
    final isLandscape = context.isLandscape;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isLandscape || isTablet ? 20 : 24),
      child: Container(
        padding: EdgeInsets.all(isLandscape || isTablet ? 24 : 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            isLandscape || isTablet ? 28 : 32,
          ),
          boxShadow: AppStyles.premiumShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isLandscape || isTablet ? 16 : 20),
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: isLandscape || isTablet ? 36 : 40,
                color: confirmColor,
              ),
            ),
            SizedBox(height: isLandscape || isTablet ? 18 : 24),
            Text(
              title,
              style: AppStyles.titleStyle.copyWith(
                fontSize: isLandscape || isTablet ? 20 : 22,
              ),
            ),
            SizedBox(height: isLandscape || isTablet ? 18 : 24),
            content,
            SizedBox(height: isLandscape || isTablet ? 24 : 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isLandscape || isTablet ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isLandscape || isTablet ? 14 : 16,
                        ),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: EdgeInsets.symmetric(
                        vertical: isLandscape || isTablet ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isLandscape || isTablet ? 14 : 16,
                        ),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
