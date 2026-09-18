import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/helper/app_logger.dart';
import 'package:pos/core/helper/backup_helper.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/app_app_bar.dart';
import 'package:pos/core/widgets/primary_button.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  static const _logTag = 'BackupRestoreScreen';
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportBackup() async {
    if (_isExporting || _isImporting) return;

    AppLogger.info('User menekan export backup', tag: _logTag);
    setState(() => _isExporting = true);
    try {
      final result = await BackupHelper.exportBackup();
      if (!mounted) return;

      ToastHelper.showSuccess(
        context,
        'Backup berhasil disimpan (${result.imageCount} gambar).',
      );
      AppLogger.info(
        'Export backup dari halaman berhasil: image_count=${result.imageCount}',
        tag: _logTag,
      );
    } on BackupCancelledException {
      AppLogger.info('Export backup dari halaman dibatalkan', tag: _logTag);
      if (!mounted) return;
      ToastHelper.showInfo(context, 'Export backup dibatalkan.');
    } catch (e) {
      AppLogger.error(
        'Export backup dari halaman gagal',
        tag: _logTag,
        error: e,
      );
      if (!mounted) return;
      ToastHelper.showError(context, _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    if (_isExporting || _isImporting) return;

    AppLogger.info('User menekan import backup', tag: _logTag);
    final confirmed = await _confirmReplace();
    if (!confirmed || !mounted) {
      AppLogger.info('Import backup tidak dikonfirmasi user', tag: _logTag);
      return;
    }

    setState(() => _isImporting = true);
    try {
      final result = await BackupHelper.importBackup();
      if (!mounted) return;

      ToastHelper.showSuccess(
        context,
        'Restore berhasil (${result.imageCount} gambar). Silakan login ulang.',
      );
      AppLogger.info(
        'Import backup dari halaman berhasil: image_count=${result.imageCount}',
        tag: _logTag,
      );
      await context.read<AuthCubit>().logout();
      if (mounted) context.go('/login');
    } on BackupCancelledException {
      AppLogger.info('Import backup dari halaman dibatalkan', tag: _logTag);
      if (!mounted) return;
      ToastHelper.showInfo(context, 'Restore backup dibatalkan.');
    } catch (e) {
      AppLogger.error(
        'Import backup dari halaman gagal',
        tag: _logTag,
        error: e,
      );
      if (!mounted) return;
      ToastHelper.showError(context, _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<bool> _confirmReplace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restore Backup?'),
          content: const Text(
            'Data lokal saat ini akan diganti dengan isi file backup. Pastikan file backup yang dipilih benar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ganti Data'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  String _friendlyError(Object error) {
    if (error is BackupValidationException) return error.message;
    return 'Proses backup gagal. Silakan coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);
    final isBusy = _isExporting || _isImporting;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Backup & Restore')),
      body: SingleChildScrollView(
        padding: ResponsiveLayout.pagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveLayout.contentMaxWidth(
                context,
                maxWidth: 760,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: isTablet ? 16.h : 20.h),
                _BackupPanel(
                  icon: Icons.download_rounded,
                  title: 'Export / Download Backup',
                  description:
                      'Simpan database, akun, produk, kategori, transaksi, laporan stok, dan gambar ke satu file ZIP.',
                  child: PrimaryButton(
                    isLoading: _isExporting,
                    label: 'DOWNLOAD BACKUP',
                    onPressed: isBusy ? null : _exportBackup,
                  ),
                ),
                SizedBox(height: 16.h),
                _BackupPanel(
                  icon: Icons.upload_file_rounded,
                  title: 'Import / Upload Backup',
                  description:
                      'Restore dari file ZIP backup. Mode restore akan mengganti seluruh data lokal yang ada.',
                  warning:
                      'Sebaiknya buat backup baru sebelum restore jika perangkat ini masih memiliki data penting.',
                  child: PrimaryButton(
                    isLoading: _isImporting,
                    label: 'UPLOAD & RESTORE',
                    onPressed: isBusy ? null : _importBackup,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupPanel extends StatelessWidget {
  const _BackupPanel({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    this.warning,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? warning;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Container(
      decoration: AppStyles.glassDecoration(
        borderRadius: isTablet ? 28.r : 32.r,
      ),
      padding: EdgeInsets.all(isTablet ? 24.w : 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 17.sp : 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: isTablet ? 12.sp : 13.sp,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (warning != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.tertiarySoft,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.tertiary.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                warning!,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
          SizedBox(height: 20.h),
          child,
        ],
      ),
    );
  }
}
