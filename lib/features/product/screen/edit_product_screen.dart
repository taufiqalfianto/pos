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
import 'package:pos/core/util/responsive_layout.dart';
import 'package:pos/core/widgets/app_app_bar.dart';
import 'package:pos/core/widgets/primary_button.dart';
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
  late final TextEditingController _costPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;
  late String _selectedCategoryId;
  String? _imagePath;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.toStringAsFixed(0),
    );
    _costPriceController = TextEditingController(
      text: widget.product.costPrice.toStringAsFixed(0),
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
    _costPriceController.dispose();
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
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      String finalImagePath = _imagePath ?? '';

      try {
        // If imagePath has changed and is not empty, save it permanently
        if (_imagePath != null &&
            _imagePath != widget.product.imagePath &&
            _imagePath!.isNotEmpty) {
          finalImagePath = await FileHelper.saveImagePermanently(_imagePath!);
        }

        if (!mounted) return;

        final updatedProduct = widget.product.copyWith(
          name: _nameController.text,
          price: double.tryParse(_priceController.text) ?? 0,
          costPrice: double.tryParse(_costPriceController.text) ?? 0,
          imagePath: finalImagePath,
          stock: int.tryParse(_stockController.text) ?? 0,
          description: _descriptionController.text,
          categoryId: _selectedCategoryId,
        );

        await context.read<ProductCubit>().updateProduct(updatedProduct);
        if (!mounted) return;
        ToastHelper.showSuccess(context, 'Produk berhasil diperbarui');
        context.pop();
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveLayout.isTablet(context);
    return Scaffold(
      appBar: AppAppBar(title: const Text('Edit Produk')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final isLandscape = context.isLandscape;
          final useLandscapeSizing = isLandscape || isTablet;
          return SingleChildScrollView(
            padding: ResponsiveLayout.pagePadding(context),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 900.w : double.infinity,
                ),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildImagePicker(
                              context,
                              isLandscape: useLandscapeSizing,
                            ),
                          ),
                          SizedBox(width: isTablet ? 24.w : 32.w),
                          Expanded(flex: 2, child: _buildForm(context)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildImagePicker(
                            context,
                            isLandscape: useLandscapeSizing,
                          ),
                          SizedBox(height: isTablet ? 24.h : 32.h),
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

  Widget _buildImagePicker(BuildContext context, {required bool isLandscape}) {
    final isTablet = ResponsiveLayout.isTablet(context);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            padding: EdgeInsets.all(isTablet ? 20.w : 24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32.r),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ubah Foto Produk',
                    style: TextStyle(
                      fontSize: isTablet ? 16.sp : 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16.h : 20.h),
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
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
                        color: AppColors.accent.withValues(alpha: 0.1),
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
        height: isLandscape
            ? (isTablet ? 200.h : 220.h)
            : (isTablet ? 260.h : 300.h),
        decoration: AppStyles.glassDecoration(borderRadius: 32),
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
                    padding: EdgeInsets.all(
                      isLandscape || isTablet ? 14.w : 20.w,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      size: isLandscape || isTablet ? 40.r : 48.r,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: isLandscape || isTablet ? 10.h : 16.h),
                  Text(
                    "Unggah Foto Produk",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "Ketuk untuk memilih",
                    style: isLandscape || isTablet
                        ? AppStyles.subtitleStyle.copyWith(fontSize: 12.sp)
                        : AppStyles.subtitleStyle,
                  ),
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
          SizedBox(height: 16.h),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Nama Produk (cth: Kopi Susu Gula Aren)',
              prefixIcon: Icon(Icons.label_rounded),
            ),
            validator: (val) => val!.isEmpty ? 'Nama tidak boleh kosong' : null,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Harga Jual',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    if (double.tryParse(val) == null || double.parse(val) < 0) {
                      return 'Harga tidak valid';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextFormField(
                  controller: _costPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Modal Produk',
                    prefixIcon: Icon(Icons.savings_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Modal tidak boleh kosong';
                    }
                    if (double.tryParse(val) == null || double.parse(val) < 0) {
                      return 'Modal tidak valid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Stok',
              prefixIcon: Icon(Icons.inventory_rounded),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Stok tidak boleh kosong';
              }
              if (int.tryParse(val) == null || int.parse(val) < 0) {
                return 'Stok tidak valid';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          _buildFieldHeader('Kategori'),
          SizedBox(height: 12.h),
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
          SizedBox(height: 16.h),
          _buildFieldHeader('Deskripsi (Opsional)'),
          SizedBox(height: 12.h),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Deskripsi Produk (cth: Kopi susu khas dengan gula aren asli)',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60.h),
                child: const Icon(Icons.notes_rounded),
              ),
            ),
          ),
          SizedBox(height: 40.h),
          PrimaryButton(
            isLoading: _isSaving,
            label: 'SIMPAN PERUBAHAN',
            onPressed: _isSaving ? null : () => _saveProduct(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 24.h,
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
