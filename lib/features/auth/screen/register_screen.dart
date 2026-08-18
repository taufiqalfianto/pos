import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:uuid/uuid.dart';
import '../cubit/auth_cubit.dart';
import '../data/model/user_model.dart';
import '../cubit/auth_state.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
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
                        padding: const EdgeInsets.all(20.0),
                        child: _buildBrandPanel(),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildAuthCard(
                            context,
                            cardPadding: EdgeInsets.all(isTablet ? 24 : 28),
                            iconSize: isTablet ? 40 : 44,
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
        padding: const EdgeInsets.all(24.0),
        child: _buildAuthCard(
          context,
          cardPadding: EdgeInsets.all(isTablet ? 28 : 32),
          iconSize: isTablet ? 44 : 48,
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
          Container(
            padding: EdgeInsets.all(isTablet ? 16.sp : 20.sp),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppStyles.premiumShadow,
            ),
            child: Icon(
              Icons.person_add_rounded,
              size: 48.r,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(height: isTablet ? 20 : 28),
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
          SizedBox(height: isTablet ? 10 : 12),
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
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppStyles.premiumShadow,
              ),
              child: Icon(
                Icons.person_add_rounded,
                size: iconSize,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: isTablet ? 20 : 24),
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
            SizedBox(height: isTablet ? 28 : 40),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              validator: (val) => val!.isEmpty ? 'Nama harus diisi' : null,
            ),
            SizedBox(height: isTablet ? 12 : 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'Username',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (val) => val!.isEmpty ? 'Username harus diisi' : null,
            ),
            SizedBox(height: isTablet ? 12 : 16),
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
            SizedBox(height: isTablet ? 28 : 40),
            SizedBox(
              width: double.infinity,
              height: isTablet ? 52 : 60,
              child: FilledButton(
                onPressed: () {
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
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 20),
                  ),
                ),
                child: Text(
                  'DAFTAR',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            SizedBox(height: isTablet ? 16 : 24),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                'Sudah punya akun? Login di sini',
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
