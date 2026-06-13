import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingMemoryService {
  static final ShoppingMemoryService instance = ShoppingMemoryService._();
  ShoppingMemoryService._();

  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isLoggedIn => _uid.isNotEmpty;

  DocumentReference get _doc => _firestore.collection('users').doc(_uid).collection('memory').doc('preferences');

  Future<Map<String, dynamic>> getMemory() async {
    if (!_isLoggedIn) return {};
    try {
      final snap = await _doc.get();
      return snap.exists ? snap.data() as Map<String, dynamic> : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> recordPurchase(List<String> productNames, List<String> categories) async {
    if (!_isLoggedIn) return;
    try {
      final memory = await getMemory();
      final previousOrders = List<String>.from(memory['previousOrders'] ?? []);
      final preferredCategories = List<String>.from(memory['preferredCategories'] ?? []);

      previousOrders.addAll(productNames);
      preferredCategories.addAll(categories);

      await _doc.set({
        'previousOrders': previousOrders.take(20).toList(),
        'preferredCategories': preferredCategories.toSet().take(10).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> recordBrandPreference(String brand) async {
    if (!_isLoggedIn) return;
    try {
      await _doc.set({
        'favoriteBrands': FieldValue.arrayUnion([brand]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<String> buildContextString() async {
    if (!_isLoggedIn) return '';
    final memory = await getMemory();
    if (memory.isEmpty) return '';

    final buffer = StringBuffer('\n\n[User Memory Context]\n');
    final orders = List<String>.from(memory['previousOrders'] ?? []);
    final brands = List<String>.from(memory['favoriteBrands'] ?? []);
    final categories = List<String>.from(memory['preferredCategories'] ?? []);

    if (orders.isNotEmpty) {
      buffer.writeln('Previously ordered: ${orders.take(5).join(', ')}');
    }
    if (brands.isNotEmpty) {
      buffer.writeln('Favorite brands: ${brands.join(', ')}');
    }
    if (categories.isNotEmpty) {
      buffer.writeln('Preferred categories: ${categories.join(', ')}');
    }
    buffer.writeln('Use this context to personalize recommendations.');
    return buffer.toString();
  }

  Future<String?> getLastOrderedProduct(String keyword) async {
    final memory = await getMemory();
    final orders = List<String>.from(memory['previousOrders'] ?? []);
    return orders.firstWhere(
      (o) => o.toLowerCase().contains(keyword.toLowerCase()),
      orElse: () => '',
    ).isEmpty ? null : orders.firstWhere((o) => o.toLowerCase().contains(keyword.toLowerCase()));
  }
}
