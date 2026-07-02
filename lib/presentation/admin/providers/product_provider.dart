import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../core/errors/app_exceptions.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo;

  ProductProvider({ProductRepository? repo})
      : _repo = repo ?? ProductRepository();

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  List<ProductModel> get filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    final q = _searchQuery.toLowerCase();
    return _products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  String _searchQuery = '';
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void init() {
    _repo.watchProducts(activeOnly: false).listen((list) {
      _products = list;
      notifyListeners();
    });
  }

  Future<bool> addProduct({
    required String name,
    required double price,
    required String description,
    required int quantity,
    File? imageFile,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.createProduct(
        name: name,
        price: price,
        description: description,
        quantity: quantity,
        imageFile: imageFile,
      );
      successMessage = 'تم إضافة المنتج بنجاح ✓';
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editProduct({
    required ProductModel product,
    File? newImageFile,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.updateProduct(product: product, newImageFile: newImageFile);
      successMessage = 'تم تعديل المنتج بنجاح ✓';
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(ProductModel product) async {
    try {
      await _repo.deleteProduct(product);
      successMessage = 'تم حذف المنتج';
      notifyListeners();
      return true;
    } on AppException catch (e) {
      errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}
