import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/product_model.dart';

class WishlistNotifier extends StateNotifier<List<Product>> {
  WishlistNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wishlist');
    if (raw != null) {
      final list = json.decode(raw) as List;
      state = list.map((e) => Product.fromMap(e)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist', json.encode(state.map((p) => p.toMap()).toList()));
  }

  void toggle(Product product) {
    if (contains(product.id)) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
    _save();
  }

  bool contains(int productId) => state.any((p) => p.id == productId);
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, List<Product>>(
  (_) => WishlistNotifier(),
);
