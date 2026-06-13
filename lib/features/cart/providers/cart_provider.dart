import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/product_model.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cart');
    if (raw != null) {
      final list = json.decode(raw) as List;
      state = list.map((e) => CartItem.fromMap(e)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart', json.encode(state.map((e) => e.toMap()).toList()));
  }

  void addProduct(Product product, {int quantity = 1}) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(quantity: state[index].quantity + quantity),
        ...state.sublist(index + 1),
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: quantity)];
    }
    _save();
  }

  void removeProduct(int productId) {
    state = state.where((i) => i.product.id != productId).toList();
    _save();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    state = state.map((i) => i.product.id == productId ? i.copyWith(quantity: quantity) : i).toList();
    _save();
  }

  void addMultipleProducts(List<Product> products) {
    for (final p in products) {
      addProduct(p);
    }
  }

  void clear() {
    state = [];
    _save();
  }

  double get total => state.fold(0, (sum, i) => sum + i.totalPriceInr);
  int get itemCount => state.fold(0, (sum, i) => sum + i.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (_) => CartNotifier(),
);

final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0.0, (sum, i) => sum + i.totalPriceInr);
});

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, i) => sum + i.quantity);
});
