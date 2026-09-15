import 'package:flutter/material.dart';
import 'package:pos/core/widgets/app_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/primary_button.dart';
import 'package:uuid/uuid.dart';
import '../cubit/auth_cubit.dart';
import '../data/model/user_model.dart';
import '../cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);
    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ToastHelper.showError(context, state.message);
          }
        },
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              if (!isLandscape || constraints.maxWidth < 700) {
                return _buildPortraitLayout(context);
              }

              return SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20.w),
                        child: _buildBrandPanel(),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(24.w),
                          child: _buildAuthCard(
                            context,
                            cardPadding: EdgeInsets.all(isTablet ? 24.w : 28.w),
                            iconSize: isTablet ? 40.r : 44.r,
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
        padding: EdgeInsets.all(24.w),
        child: _buildAuthCard(
          context,
          cardPadding: EdgeInsets.all(isTablet ? 28.w : 32.w),
          iconSize: isTablet ? 44.r : 48.r,
          titleFontSize: isTablet ? 28.sp : 32.sp,
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    final responsive = ResponsiveLayout.of(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLogo(size: 48.r + (isTablet ? 32.sp : 40.sp)),
          SizedBox(height: 28.h),
          SizedBox(height: isTablet ? 20.h : 28.h),
          Text(
            'Buat Akun',
            style: TextStyle(
              fontSize: responsive.isLandscape
                  ? (isTablet ? 13.sp : 12.sp)
                  : (isTablet ? 14.sp : 16.sp),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1.2,
            ),
          ),
          SizedBox(height: isTablet ? 10.h : 12.h),
          Text(
            'Landscape memberi ruang lebih lega untuk mengisi data registrasi dengan nyaman.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: responsive.isLandscape
                  ? (isTablet ? 9.sp : 8.sp)
                  : (isTablet ? 12.sp : 16.sp),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(
    BuildContext context, {
    required EdgeInsets cardPadding,
    required double iconSize,
    required double titleFontSize,
  }) {
    final responsive = ResponsiveLayout.of(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    return Container(
      constraints: BoxConstraints(maxWidth: isTablet ? 440 : 400),
      decoration: AppStyles.glassDecoration(
        borderRadius: isTablet ? 30 : 32,
        blur: 20,
      ),
      padding: cardPadding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: iconSize + (isTablet ? 32.r : 40.r)),
            SizedBox(height: isTablet ? 20.h : 24.h),
            Text(
              'Buat Akun',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -1,
              ),
            ),
            Text(
              'Daftar akun baru untuk mulai menggunakan POS',
              style: AppStyles.subtitleStyle.copyWith(
                fontSize: responsive.isLandscape
                    ? (isTablet ? 9.sp : 8.sp)
                    : (isTablet ? 12.sp : 16.sp),
              ),
            ),
            SizedBox(height: isTablet ? 28.h : 40.h),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              validator: (val) => val!.isEmpty ? 'Nama harus diisi' : null,
            ),
            SizedBox(height: isTablet ? 12.h : 16.h),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'Username',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (val) => val!.isEmpty ? 'Username harus diisi' : null,
            ),
            SizedBox(height: isTablet ? 12.h : 16.h),
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
              validator: (val) {
                if (val!.isEmpty) return 'Password harus diisi';
                if (val.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            SizedBox(height: isTablet ? 28.h : 40.h),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return PrimaryButton(
                  isLoading: isLoading,
                  label: 'DAFTAR',
                  onPressed: isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            final user = UserModel(
                              id: const Uuid().v4(),
                              name: _nameController.text,
                              username: _usernameController.text,
                              password: _passwordController.text,
                            );
                            context.read<AuthCubit>().register(user);
                          }
                        },
                );
              },
            ),
            SizedBox(height: isTablet ? 16.h : 24.h),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return TextButton(
                  onPressed: isLoading ? null : () => context.go('/login'),
                  child: const Text(
                    'Sudah punya akun? Login di sini',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
