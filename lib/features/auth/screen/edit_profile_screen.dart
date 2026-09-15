import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/app_app_bar.dart';
import 'package:pos/core/widgets/primary_button.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  String? _pickedImagePath;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _nameController = TextEditingController(text: authState.user.name);
      _usernameController = TextEditingController(
        text: authState.user.username,
      );
      _pickedImagePath = authState.user.imagePath;
    } else {
      _nameController = TextEditingController();
      _usernameController = TextEditingController();
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImagePath = image.path;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        setState(() => _isSaving = true);
        String finalImagePath = _pickedImagePath ?? '';

        try {
          // Save image permanently if it's a new temporary file
          if (finalImagePath.isNotEmpty &&
              finalImagePath != authState.user.imagePath) {
            finalImagePath = await FileHelper.saveImagePermanently(
              finalImagePath,
            );
          }

          if (!mounted) return;

          final updatedUser = authState.user.copyWith(
            name: _nameController.text,
            username: _usernameController.text,
            imagePath: finalImagePath,
          );

          await context.read<AuthCubit>().updateProfile(updatedUser);
          if (!mounted) return;
          ToastHelper.showSuccess(context, 'Profil berhasil diperbarui');
          context.pop();
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);

    return Scaffold(
      appBar: AppAppBar(title: const Text('Edit Profil')),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ToastHelper.showError(context, state.message);
          }
        },
        child: LayoutBuilder(
          builder: (context, _) {
            final isLandscape = context.isLandscape;
            return SingleChildScrollView(
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
                    children: [
                      SizedBox(height: isTablet ? 16.h : 20.h),
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isTablet ? 6.w : 8.w),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: isLandscape
                                      ? (isTablet ? 48.r : 52.r)
                                      : (isTablet ? 56.r : 60.r),
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      _pickedImagePath != null &&
                                          _pickedImagePath!.isNotEmpty
                                      ? FileImage(
                                          File(
                                            FileHelper.getFullPath(
                                              _pickedImagePath!,
                                            ),
                                          ),
                                        )
                                      : null,
                                  child:
                                      _pickedImagePath == null ||
                                          _pickedImagePath!.isEmpty
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 80.r,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isTablet ? 2.w : 3.w,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18.r,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: isLandscape
                            ? (isTablet ? 28.h : 32.h)
                            : (isTablet ? 40.h : 48.h),
                      ),
                      Container(
                        decoration: AppStyles.glassDecoration(
                          borderRadius: isTablet ? 28.r : 32.r,
                        ),
                        padding: EdgeInsets.all(
                          isLandscape
                              ? (isTablet ? 20.w : 24.w)
                              : (isTablet ? 28.w : 32.w),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader('Informasi Akun'),
                              SizedBox(height: isTablet ? 20.h : 24.h),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Nama Lengkap',
                                  prefixIcon: Icon(Icons.badge_rounded),
                                ),
                                validator: (val) =>
                                    val!.isEmpty ? 'Nama harus diisi' : null,
                              ),
                              SizedBox(height: isTablet ? 12.h : 16.h),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  hintText: 'Username',
                                  prefixIcon: Icon(Icons.person_rounded),
                                ),
                                validator: (val) => val!.isEmpty
                                    ? 'Username harus diisi'
                                    : null,
                              ),
                              SizedBox(height: isTablet ? 28.h : 40.h),
                              PrimaryButton(
                                isLoading: _isSaving,
                                label: 'SIMPAN PERUBAHAN',
                                onPressed: _isSaving ? null : _saveProfile,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 24.h : 32.h),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.data?.version ?? '1.0.0';
                          final buildNumber = snapshot.data?.buildNumber ?? '1';
                          return Text(
                            'App Version $version ($buildNumber)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isTablet ? 12.h : 16.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
