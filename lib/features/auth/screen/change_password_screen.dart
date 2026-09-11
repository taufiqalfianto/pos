import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/loading_button_child.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isOldObscure = true;
  bool _isNewObscure = true;
  bool _isSaving = false;

  Future<void> _savePassword() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await context.read<AuthCubit>().changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    final state = context.read<AuthCubit>().state;
    if (state is Authenticated) {
      ToastHelper.showSuccess(context, 'Password berhasil diubah');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan')),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ToastHelper.showError(context, state.message);
          }
        },
        child: LayoutBuilder(
          builder: (context, _) {
            return SingleChildScrollView(
              padding: ResponsiveLayout.pagePadding(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayout.contentMaxWidth(
                      context,
                      maxWidth: 720,
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      Container(
                        decoration: AppStyles.glassDecoration(
                          borderRadius: 32.r,
                        ),
                        padding: EdgeInsets.all(
                          context.isLandscape ? 24.w : 32.w,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.lock_reset_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ubah Password',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Gunakan password yang kuat',
                                          style: AppStyles.subtitleStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 40.h),
                              _buildPasswordField(
                                controller: _oldPasswordController,
                                hint: 'Password Lama',
                                isObscure: _isOldObscure,
                                onToggle: () => setState(
                                  () => _isOldObscure = !_isOldObscure,
                                ),
                                validator: (val) => val!.isEmpty
                                    ? 'Password lama harus diisi'
                                    : null,
                              ),
                              SizedBox(height: 16.h),
                              Divider(height: 32.h),
                              _buildPasswordField(
                                controller: _newPasswordController,
                                hint: 'Password Baru',
                                isObscure: _isNewObscure,
                                onToggle: () => setState(
                                  () => _isNewObscure = !_isNewObscure,
                                ),
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'Password baru harus diisi';
                                  }
                                  if (val.length < 6) {
                                    return 'Minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  hintText: 'Konfirmasi Password Baru',
                                  prefixIcon: Icon(
                                    Icons.check_circle_outline_rounded,
                                  ),
                                ),
                                validator: (val) {
                                  if (val != _newPasswordController.text) {
                                    return 'Password tidak cocok';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 48.h),
                              SizedBox(
                                height: ResponsiveLayout.adaptiveValue(
                                  context,
                                  portrait: 60,
                                  landscape: 52,
                                  tablet: 52,
                                ).h,
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _savePassword,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                  ),
                                  child: LoadingButtonChild(
                                    isLoading: _isSaving,
                                    label: 'UPDATE PASSWORD',
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
