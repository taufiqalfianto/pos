import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                decoration: AppStyles.glassDecoration(borderRadius: 32.r),
                padding: EdgeInsets.all(32.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 40),
                      _buildPasswordField(
                        controller: _oldPasswordController,
                        hint: 'Password Lama',
                        isObscure: _isOldObscure,
                        onToggle: () =>
                            setState(() => _isOldObscure = !_isOldObscure),
                        validator: (val) =>
                            val!.isEmpty ? 'Password lama harus diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 32),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        hint: 'Password Baru',
                        isObscure: _isNewObscure,
                        onToggle: () =>
                            setState(() => _isNewObscure = !_isNewObscure),
                        validator: (val) {
                          if (val!.isEmpty) return 'Password baru harus diisi';
                          if (val.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Konfirmasi Password Baru',
                          prefixIcon: Icon(Icons.check_circle_outline_rounded),
                        ),
                        validator: (val) {
                          if (val != _newPasswordController.text)
                            return 'Password tidak cocok';
                          return null;
                        },
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        height: 60,
                        child: FilledButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthCubit>().changePassword(
                                _oldPasswordController.text,
                                _newPasswordController.text,
                              );
                              ToastHelper.showSuccess(
                                context,
                                'Password berhasil diubah',
                              );
                              context.pop();
                            }
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'UPDATE PASSWORD',
                            style: TextStyle(
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
