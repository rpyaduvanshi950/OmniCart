import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/product_model.dart';

class ProductApiService {
  static final ProductApiService instance = ProductApiService._();
  ProductApiService._();

  String get _baseUrl => dotenv.env['PRODUCT_API_BASE_URL'] ?? 'https://dummyjson.com';

  Future<List<Product>> fetchProducts({int limit = 20, int skip = 0}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products?limit=$limit&skip=$skip&select=title,price,thumbnail,images,rating,stock,category,description,discountPercentage'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data['products'] as List).map((p) => Product.fromDummyJson(p)).toList();
    }
    throw Exception('Failed to fetch products');
  }

  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products/search?q=${Uri.encodeComponent(query)}&limit=$limit'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data['products'] as List).map((p) => Product.fromDummyJson(p)).toList();
    }
    return [];
  }

  Future<List<Product>> fetchByCategory(String category, {int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products/category/$category?limit=$limit'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return (data['products'] as List).map((p) => Product.fromDummyJson(p)).toList();
    }
    return [];
  }

  Future<List<String>> fetchCategories() async {
    final res = await http.get(Uri.parse('$_baseUrl/products/category-list'));
    if (res.statusCode == 200) {
      return List<String>.from(json.decode(res.body));
    }
    return [];
  }

  Future<Product?> fetchProductById(int id) async {
    final res = await http.get(Uri.parse('$_baseUrl/products/$id'));
    if (res.statusCode == 200) {
      return Product.fromDummyJson(json.decode(res.body));
    }
    return null;
  }
}
