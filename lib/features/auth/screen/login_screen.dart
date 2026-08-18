import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import '../../../core/util/responsive_layout.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveLayout.of(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ToastHelper.showError(context, state.message);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape =
                  responsive.isLandscape && constraints.maxWidth >= 700;

              if (!isLandscape) {
                return _buildPortraitLayout(context);
              }

              return SafeArea(
                child: Row(
                  children: [
                    Expanded(flex: 5, child: _buildBrandPanel()),
                    Expanded(
                      flex: 7,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(24.w),
                          child: _buildAuthCard(
                            context,
                            cardPadding: EdgeInsets.all(isTablet ? 24.r : 28.r),
                            logoSize: isTablet ? 76 : 84,
                            titleFontSize: isTablet ? 24.sp : 28.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Center(
      child: SingleChildScrollView(
        padding: ResponsiveLayout.pagePadding(context),
        child: _buildAuthCard(
          context,
          cardPadding: EdgeInsets.all(isTablet ? 24.r : 28.r),
          logoSize: isTablet ? 88.w : 100.w,
          titleFontSize: isTablet ? 28.sp : 32.sp,
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    final responsive = ResponsiveLayout.of(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 16.w : 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: responsive.isLandscape
                  ? (isTablet ? 64.w : 50.w)
                  : (isTablet ? 88.w : 100.w),
              height: responsive.isLandscape
                  ? (isTablet ? 64.w : 50.w)
                  : (isTablet ? 88.w : 100.w),
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://corenews.id/wp-content/uploads/2024/08/PosInd.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppStyles.premiumShadow,
              ),
            ),
            SizedBox(
              height: responsive.isLandscape
                  ? (isTablet ? 10.h : 12.h)
                  : (isTablet ? 20.h : 28.h),
            ),
            Text(
              'Premium POS',
              style: TextStyle(
                fontSize: responsive.isLandscape
                    ? (isTablet ? 13.sp : 12.sp)
                    : (isTablet ? 14.sp : 16.sp),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1.2,
              ),
            ),
            SizedBox(
              height: responsive.isLandscape
                  ? (isTablet ? 4.h : 6.h)
                  : (isTablet ? 10.h : 12.h),
            ),
            Text(
              'Akses lebih cepat saat digunakan dalam mode landscape, dengan ruang kerja yang lebih lega.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: responsive.isLandscape
                    ? (isTablet ? 9.sp : 8.sp)
                    : (isTablet ? 12.sp : 14.sp),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard(
    BuildContext context, {
    required EdgeInsets cardPadding,
    required double logoSize,
    required double titleFontSize,
  }) {
    final responsive = ResponsiveLayout.of(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    return Container(
      constraints: BoxConstraints(maxWidth: isTablet ? 360.w : 300.w),
      decoration: AppStyles.glassDecoration(
        borderRadius: responsive.isLandscape
            ? (isTablet ? 30 : 28)
            : (isTablet ? 34 : 32),
        blur: 20,
      ),
      padding: cardPadding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://corenews.id/wp-content/uploads/2024/08/PosInd.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppStyles.premiumShadow,
              ),
            ),
            SizedBox(height: isTablet ? 20.h : 24.h),
            Text(
              'Premium POS',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            Text(
              'Silakan login untuk melanjutkan',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: responsive.isLandscape
                    ? (isTablet ? 10.sp : 8.sp)
                    : (isTablet ? 12.sp : 14.sp),
                height: 1.4,
              ),
            ),
            SizedBox(height: isTablet ? 24.h : 32.h),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'Username',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (val) => val!.isEmpty ? 'Username harus diisi' : null,
            ),
            SizedBox(height: isTablet ? 12.h : 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              validator: (val) => val!.isEmpty ? 'Password harus diisi' : null,
            ),
            SizedBox(height: isTablet ? 28.h : 40),
            SizedBox(
              width: double.infinity,
              height: isTablet ? 52.h : 56.h,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthCubit>().login(
                      _usernameController.text,
                      _passwordController.text,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 16.r : 18.r),
                  ),
                ),
                child: Text(
                  'Masuk Sekarang',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 16.h : 20.h),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text(
                'Belum punya akun? Daftar gratis',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
