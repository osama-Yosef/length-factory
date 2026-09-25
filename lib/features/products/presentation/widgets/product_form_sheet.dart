import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/cubit/submission_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/product_actions_cubit.dart';

/// Add / edit product bottom sheet. Requires [ProductActionsCubit] above.
class ProductFormSheet extends StatefulWidget {
  final ProductEntity? product;
  const ProductFormSheet({super.key, this.product});

  static Future<void> show(BuildContext context, {ProductEntity? product}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ProductActionsCubit>(),
        child: ProductFormSheet(product: product),
      ),
    );
  }

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.product?.name);
  late final _priceCtrl = TextEditingController(text: _num(widget.product?.price));
  late final _qtyCtrl = TextEditingController(text: widget.product?.quantity.toString());
  late final _descCtrl = TextEditingController(text: widget.product?.description);
  String? _imagePath;
  bool _submitted = false;

  bool get _isEdit => widget.product != null;

  static String? _num(double? v) {
    if (v == null) return null;
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _priceCtrl, _qtyCtrl, _descCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _submitted = true;
    final cubit = context.read<ProductActionsCubit>();
    final name = _nameCtrl.text.trim();
    final price = double.parse(_priceCtrl.text.trim());
    final qty = int.parse(_qtyCtrl.text.trim());
    final desc = _descCtrl.text.trim();

    if (_isEdit) {
      cubit.update(
        widget.product!.copyWith(name: name, price: price, quantity: qty, description: desc),
        newImagePath: _imagePath,
      );
    } else {
      cubit.add(ProductDraft(
        name: name,
        price: price,
        description: desc,
        quantity: qty,
        imagePath: _imagePath,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductActionsCubit, SubmissionState>(
      listener: (context, state) {
        if (_submitted && state is SubmissionSuccess) Navigator.of(context).pop();
      },
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEdit ? 'تعديل المنتج' : 'إضافة منتج جديد',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  _ImagePickerBox(
                    localPath: _imagePath,
                    remoteUrl: widget.product?.imageUrl ?? '',
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج *',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) => Validators.required(v, 'أدخل اسم المنتج'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'السعر (ج.م) *',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                          validator: (v) => Validators.positiveNumber(v, field: 'السعر'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'الكمية بالمخزون *',
                            prefixIcon: Icon(Icons.inventory_outlined),
                          ),
                          validator: (v) => Validators.nonNegativeInt(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (state is SubmissionFailure) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: _isEdit ? 'حفظ التعديلات' : 'إضافة المنتج',
                    icon: _isEdit ? Icons.save_outlined : Icons.add,
                    isLoading: state is SubmissionLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final String? localPath;
  final String remoteUrl;
  final VoidCallback onTap;

  const _ImagePickerBox({required this.localPath, required this.remoteUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (localPath != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(localPath!), fit: BoxFit.cover, width: double.infinity),
      );
    } else if (remoteUrl.isNotEmpty) {
      content = ProductImage(url: remoteUrl, width: double.infinity, height: 150);
    } else {
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
          SizedBox(height: 8),
          Text('اضغط لإضافة صورة',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (localPath != null || remoteUrl.isNotEmpty)
              const PositionedDirectional(
                bottom: 8,
                end: 8,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.edit, size: 18, color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
