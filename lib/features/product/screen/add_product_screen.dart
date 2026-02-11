import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/features/product/data/model/product_model.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/helper/file_helper.dart';
import '../cubit/product_cubit.dart';

import '../cubit/category_cubit.dart';
import '../data/model/category_model.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategoryId = 'general';
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().loadCategories();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      String finalImagePath = _imagePath ?? '';

      if (_imagePath != null && _imagePath!.isNotEmpty) {
        finalImagePath = await FileHelper.saveImagePermanently(_imagePath!);
      }

      final product = ProductModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        price: double.parse(_priceController.text),
        imagePath: finalImagePath,
        stock: int.parse(_stockController.text),
        description: _descriptionController.text,
        categoryId: _selectedCategoryId,
      );

      context.read<ProductCubit>().addProduct(product);
      ToastHelper.showSuccess(context, 'Produk berhasil disimpan');
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Produk')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 900 : double.infinity,
                ),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildImagePicker(context)),
                          const SizedBox(width: 32),
                          Expanded(flex: 2, child: _buildForm(context)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildImagePicker(context),
                          const SizedBox(height: 32),
                          _buildForm(context),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pilih Foto Produk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: const Text(
                      'Kamera',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    title: const Text(
                      'Galeri',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 300.h,
        decoration: AppStyles.glassDecoration(borderRadius: 32.r),
        clipBehavior: Clip.antiAlias,
        child: _imagePath != null
            ? Image.file(
                File(FileHelper.getFullPath(_imagePath!)),
                fit: BoxFit.cover,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Unggah Foto Produk",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text("Ketuk untuk memilih", style: AppStyles.subtitleStyle),
                ],
              ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldHeader('Detail Produk'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Nama Produk (cth: Kopi Susu Gula Aren)',
              prefixIcon: Icon(Icons.label_rounded),
            ),
            validator: (val) => val!.isEmpty ? 'Nama tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Harga',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Harga tidak boleh kosong' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Stok',
                    prefixIcon: Icon(Icons.inventory_rounded),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Stok tidak boleh kosong' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldHeader('Kategori'),
          const SizedBox(height: 12),
          BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, state) {
              List<CategoryModel> categories = [];
              if (state is CategoryLoaded) {
                categories = state.categories;
              }
              return DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded),
                  hintText: 'Pilih Kategori',
                ),
                items: categories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategoryId = val);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildFieldHeader('Deskripsi (Opsional)'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Deskripsi Produk (cth: Kopi susu khas dengan gula aren asli)',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.notes_rounded),
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 60,
            child: FilledButton(
              onPressed: () => _saveProduct(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'SIMPAN PRODUK',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
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
