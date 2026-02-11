import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/util/modern_dialog.dart';
import '../cubit/category_cubit.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().loadCategories();
  }

  void _showAddDialog() {
    ModernDialog.show(
      context: context,
      title: 'Tambah Kategori',
      icon: Icons.category_rounded,
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Nama Kategori (cth: Minuman)',
        ),
      ),
      confirmText: 'TAMBAH',
      onConfirm: () {
        if (_nameController.text.isNotEmpty) {
          context.read<CategoryCubit>().addCategory(_nameController.text);
          _nameController.clear();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: BlocConsumer<CategoryCubit, CategoryState>(
        listener: (context, state) {
          if (state is CategoryError) {
            ToastHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CategoryLoaded) {
            if (state.categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text('Belum ada kategori', style: AppStyles.subtitleStyle),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final isGeneral = category.id == 'general';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!isGeneral)
                        IconButton(
                          onPressed: () {
                            ModernDialog.show(
                              context: context,
                              title: 'Hapus Kategori',
                              icon: Icons.delete_outline_rounded,
                              content: Text(
                                'Hapus "${category.name}"? Produk di kategori ini akan dipindah ke "Umum".',
                                textAlign: TextAlign.center,
                                style: AppStyles.subtitleStyle.copyWith(
                                  fontSize:
                                      AppStyles.subtitleStyle.fontSize?.sp,
                                ),
                              ),
                              confirmText: 'HAPUS',
                              confirmColor: AppColors.error,
                              onConfirm: () => context
                                  .read<CategoryCubit>()
                                  .deleteCategory(category.id),
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
