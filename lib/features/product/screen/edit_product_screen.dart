import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/features/product/data/model/product_model.dart';
import 'package:pos/features/product/data/model/category_model.dart';
import 'package:pos/core/helper/file_helper.dart';
import '../cubit/product_cubit.dart';
import '../cubit/category_cubit.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;
  late String _selectedCategoryId;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _imagePath = widget.product.imagePath.isEmpty
        ? null
        : widget.product.imagePath;
    _selectedCategoryId = widget.product.categoryId;
    context.read<CategoryCubit>().loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

      // If imagePath has changed and is not empty, save it permanently
      if (_imagePath != null &&
          _imagePath != widget.product.imagePath &&
          _imagePath!.isNotEmpty) {
        finalImagePath = await FileHelper.saveImagePermanently(_imagePath!);
      }

      final updatedProduct = widget.product.copyWith(
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        imagePath: finalImagePath,
        stock: int.tryParse(_stockController.text) ?? 0,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId,
      );

      context.read<ProductCubit>().updateProduct(updatedProduct);
      ToastHelper.showSuccess(context, 'Produk berhasil diperbarui');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Produk')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 900.w : double.infinity,
                ),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildImagePicker(context)),
                          SizedBox(width: 32.w),
                          Expanded(flex: 2, child: _buildForm(context)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildImagePicker(context),
                          SizedBox(height: 32.h),
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
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ubah Foto Produk',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      'Kamera',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    title: Text(
                      'Galeri',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
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
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      size: 48.w,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
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
          _buildFieldHeader('Update Informasi Produk'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Nama Produk',
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
          _buildFieldHeader('Deskripsi Produk'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Deskripsi Produk',
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
                'SIMPAN PERUBAHAN',
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
