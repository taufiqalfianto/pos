import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/helper/local_data_warning_helper.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/app_logo.dart';
import 'package:pos/core/widgets/loading_button_child.dart';
import 'package:pos/features/auth/cubit/auth_cubit.dart';
import 'package:pos/features/auth/cubit/auth_state.dart';

class LocalDataWarningScreen extends StatefulWidget {
  const LocalDataWarningScreen({super.key});

  @override
  State<LocalDataWarningScreen> createState() => _LocalDataWarningScreenState();
}

class _LocalDataWarningScreenState extends State<LocalDataWarningScreen> {
  bool _isAccepting = false;

  Future<void> _continue() async {
    if (_isAccepting) return;

    setState(() => _isAccepting = true);
    await LocalDataWarningHelper.acceptWarning();

    if (!mounted) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = context.isLandscape;
    final isTablet = ResponsiveLayout.isTablet(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: ResponsiveLayout.pagePadding(
                context,
                portrait: 20,
                landscape: 28,
                vertical: isLandscape ? 16 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveLayout.contentMaxWidth(
                    context,
                    maxWidth: isLandscape ? 860 : 560,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 28.w : 24.w),
                  decoration: AppStyles.glassDecoration(
                    borderRadius: isTablet ? 32 : 28,
                    color: Colors.white,
                    blur: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLogo(size: isTablet ? 64.w : 56.w),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Peringatan Penyimpanan Lokal',
                                  style: TextStyle(
                                    fontSize: isTablet ? 22.sp : 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  'Harap dibaca sebelum mulai menggunakan Premium POS.',
                                  style: AppStyles.subtitleStyle.copyWith(
                                    fontSize: isTablet ? 14.sp : 13.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.tertiarySoft,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: AppColors.tertiary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.tertiaryDark,
                              size: 28.r,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Aplikasi ini belum memiliki sinkronisasi server. Data produk, stok, transaksi, laporan, dan akun disimpan di perangkat ini.',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 22.h),
                      _WarningItem(
                        icon: Icons.delete_forever_outlined,
                        title: 'Jangan uninstall aplikasi',
                        description:
                            'Menghapus aplikasi dapat menghapus database lokal dan sesi akun di perangkat.',
                      ),
                      _WarningItem(
                        icon: Icons.system_update_alt_rounded,
                        title: 'Update harus memakai aplikasi yang sama',
                        description:
                            'Pastikan package name dan tanda tangan aplikasi tetap sama agar Android mempertahankan data lokal saat update.',
                      ),
                      _WarningItem(
                        icon: Icons.storage_rounded,
                        title: 'Jaga penyimpanan perangkat',
                        description:
                            'Storage penuh bisa membuat transaksi, foto produk, atau update database gagal disimpan.',
                      ),
                      _WarningItem(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Hindari clear data atau wipe emulator',
                        description:
                            'Clear data, reset pabrik, atau wipe data emulator akan menghapus data POS yang tersimpan lokal.',
                      ),
                      _WarningItem(
                        icon: Icons.backup_outlined,
                        title: 'Backup tetap disarankan',
                        description:
                            'Sebelum update besar atau pindah perangkat, buat salinan data secara manual sampai fitur sinkron server tersedia.',
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Dengan melanjutkan, Anda memahami bahwa data operasional saat ini bergantung pada perangkat ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        height: ResponsiveLayout.adaptiveValue(
                          context,
                          portrait: 56,
                          landscape: 50,
                          tablet: 52,
                        ).h,
                        child: FilledButton(
                          onPressed: _isAccepting ? null : _continue,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.r),
                            ),
                          ),
                          child: LoadingButtonChild(
                            isLoading: _isAccepting,
                            label: 'SAYA MENGERTI, LANJUTKAN',
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WarningItem extends StatelessWidget {
  const _WarningItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(9.w),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
