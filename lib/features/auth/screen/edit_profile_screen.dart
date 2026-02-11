import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/helper/file_helper.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

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
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        String finalImagePath = _pickedImagePath ?? '';

        // Save image permanently if it's a new temporary file
        if (finalImagePath.isNotEmpty &&
            finalImagePath != authState.user.imagePath) {
          finalImagePath = await FileHelper.saveImagePermanently(
            finalImagePath,
          );
        }

        final updatedUser = authState.user.copyWith(
          name: _nameController.text,
          username: _usernameController.text,
          imagePath: finalImagePath,
        );
        context.read<AuthCubit>().updateProfile(updatedUser);
        ToastHelper.showSuccess(context, 'Profil berhasil diperbarui');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
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
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              _pickedImagePath != null &&
                                  _pickedImagePath!.isNotEmpty
                              ? FileImage(
                                  File(
                                    FileHelper.getFullPath(_pickedImagePath!),
                                  ),
                                )
                              : null,
                          child:
                              _pickedImagePath == null ||
                                  _pickedImagePath!.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 80,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Container(
                decoration: AppStyles.glassDecoration(borderRadius: 32),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader('Informasi Akun'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.badge_rounded),
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Nama harus diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Username',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Username harus diisi' : null,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 60,
                        child: FilledButton(
                          onPressed: _saveProfile,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'SIMPAN PERUBAHAN',
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
              const SizedBox(height: 32),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.0.0';
                  final buildNumber = snapshot.data?.buildNumber ?? '1';
                  return Text(
                    'App Version $version ($buildNumber)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
