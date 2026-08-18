import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/util/app_style.dart';
import 'package:pos/core/helper/toast_helper.dart';
import 'package:pos/core/util/responsive_layout.dart';
import '../cubit/stock_report_cubit.dart';
import '../data/model/product_model.dart';
import '../data/model/stock_report_model.dart';
import '../cubit/product_cubit.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AddStockReportScreen extends StatefulWidget {
  final ProductModel product;
  const AddStockReportScreen({super.key, required this.product});

  @override
  State<AddStockReportScreen> createState() => _AddStockReportScreenState();
}

class _AddStockReportScreenState extends State<AddStockReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _noteController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final manualStock = int.parse(_countController.text);
      final systemStock = widget.product.stock;
      final adjustment = manualStock - systemStock;

      final report = StockReportModel(
        id: const Uuid().v4(),
        productId: widget.product.id,
        productName: widget.product.name,
        systemStock: systemStock,
        manualStock: manualStock,
        adjustment: adjustment,
        note: _noteController.text,
        createdAt: DateTime.now(),
      );

      context.read<StockReportCubit>().submitReport(report);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Stok Manual')),
      body: BlocListener<StockReportCubit, StockReportState>(
        listener: (context, state) {
          if (state is StockReportSuccess) {
            ToastHelper.showSuccess(context, 'Laporan stok berhasil disimpan');
            context.read<ProductCubit>().loadProducts();
            Navigator.pop(context);
          } else if (state is StockReportError) {
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
                      maxWidth: 720,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProductInfo(),
                        SizedBox(height: isLandscape ? 24 : 32),
                        Text(
                          'Berapa jumlah stok fisik yang tersedia?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _countController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Jumlah stok (cth: 25)',
                            prefixIcon: Icon(Icons.calculate_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Jumlah tidak boleh kosong';
                            }
                            if (int.tryParse(val) == null) {
                              return 'Gunakan angka saja';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Catatan (Opsional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Tambahkan alasan penyesuaian (cth: Stok rusak, salah hitung)',
                            prefixIcon: Icon(Icons.note_alt_rounded),
                          ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          height: ResponsiveLayout.adaptiveValue(
                            context,
                            portrait: 60,
                            landscape: 52,
                            tablet: 52,
                          ),
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                            child: const Text(
                              'SIMPAN PENYESUAIAN',
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Stok sistem saat ini: ${widget.product.stock}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
