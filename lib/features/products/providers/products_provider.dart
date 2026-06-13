import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/product_api_service.dart';
import '../../../models/product_model.dart';

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  return ProductApiService.instance.fetchCategories();
});

final allProductsProvider = FutureProvider.family<List<Product>, int>((ref, page) async {
  return ProductApiService.instance.fetchProducts(limit: 20, skip: page * 20);
});

final productsByCategoryProvider = FutureProvider.family<List<Product>, String>((ref, category) async {
  return ProductApiService.instance.fetchByCategory(category);
});

final productSearchProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  return ProductApiService.instance.searchProducts(query);
});

final productDetailProvider = FutureProvider.family<Product?, int>((ref, id) async {
  return ProductApiService.instance.fetchProductById(id);
});

final searchQueryProvider = StateProvider<String>((_) => '');
final selectedCategoryProvider = StateProvider<String?>((_) => null);
