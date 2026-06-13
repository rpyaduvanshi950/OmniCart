import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/product_api_service.dart';
import '../../../core/services/shopping_memory_service.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';

class AiAssistantNotifier extends StateNotifier<List<ChatMessage>> {
  AiAssistantNotifier(this._ref) : super([]) {
    _initWithMemory();
  }

  final Ref _ref;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> _initWithMemory() async {
    final memoryContext = await ShoppingMemoryService.instance.buildContextString();
    if (memoryContext.isNotEmpty) {
      await GeminiService.instance.sendMessage('__MEMORY_CONTEXT__ $memoryContext');
    }
    state = [
      ChatMessage.assistant(
        "Hi! I'm your OmniCart AI assistant. 🛒\n\nTell me what you'd like to shop for:",
        quickReplies: [
          'Gaming mouse under ₹2000',
          'Groceries for a week',
          'Gift under ₹1500',
          'Best laptop for coding',
        ],
      ),
    ];
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    _isLoading = true;

    state = [...state, ChatMessage.user(text)];
    final loadingId = '${DateTime.now().millisecondsSinceEpoch}_loading';
    final loadingMsg = ChatMessage(
      id: loadingId,
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    state = [...state, loadingMsg];

    try {
      final response = await GeminiService.instance.sendMessage(text);
      // Strip the <products>…</products> block from visible text
      final visibleText = response.replaceAll(RegExp(r'<products>.*?</products>', dotAll: true), '').trim();

      final products = await _fetchProductsFromResponse(response);

      final List<String> quickReplies = _buildQuickReplies(products);

      final newMsg = products.isNotEmpty
          ? ChatMessage.assistantWithProducts(visibleText, products, quickReplies: quickReplies)
          : ChatMessage.assistant(visibleText).copyWith(quickReplies: quickReplies);

      state = [...state.where((m) => m.id != loadingId), newMsg];
    } catch (e) {
      state = [
        ...state.where((m) => m.id != loadingId),
        ChatMessage.assistant('Sorry, something went wrong. Please try again.'),
      ];
    } finally {
      _isLoading = false;
    }
  }

  // Maps common product keywords to DummyJSON catalog categories
  static const _keywordToCategory = {
    'mouse': 'mobile-accessories',
    'keyboard': 'mobile-accessories',
    'gaming': 'mobile-accessories',
    'headphone': 'mobile-accessories',
    'earphone': 'mobile-accessories',
    'earbuds': 'mobile-accessories',
    'speaker': 'mobile-accessories',
    'charger': 'mobile-accessories',
    'smartwatch': 'mobile-accessories',
    'laptop': 'laptops',
    'notebook': 'laptops',
    'macbook': 'laptops',
    'phone': 'smartphones',
    'smartphone': 'smartphones',
    'mobile': 'smartphones',
    'iphone': 'smartphones',
    'tablet': 'tablets',
    'ipad': 'tablets',
    'watch': 'mens-watches',
    'sunglasses': 'sunglasses',
    'shirt': 'mens-shirts',
    'shoes': 'mens-shoes',
    'sneaker': 'mens-shoes',
    'bag': 'womens-bags',
    'dress': 'womens-dresses',
    'furniture': 'furniture',
    'sofa': 'furniture',
    'chair': 'furniture',
    'groceries': 'groceries',
    'grocery': 'groceries',
    'food': 'groceries',
    'skincare': 'skin-care',
    'skin': 'skin-care',
    'beauty': 'beauty',
    'makeup': 'beauty',
    'perfume': 'fragrances',
    'deodorant': 'fragrances',
    'sports': 'sports-accessories',
    'gym': 'sports-accessories',
    'cricket': 'sports-accessories',
    'football': 'sports-accessories',
    'kitchen': 'kitchen-accessories',
    'cookware': 'kitchen-accessories',
    'home': 'home-decoration',
    'decor': 'home-decoration',
    'jewellery': 'womens-jewellery',
    'jewelry': 'womens-jewellery',
    'necklace': 'womens-jewellery',
    'ring': 'womens-jewellery',
    'bike': 'motorcycle',
    'car': 'vehicle',
  };

  Future<List<Product>> _fetchProductsFromResponse(String response) async {
    List<Map<String, dynamic>> suggestions = [];

    // Primary: parse <products> JSON block
    final tagsRegex = RegExp(r'<products>(.*?)</products>', dotAll: true);
    final tagMatch = tagsRegex.firstMatch(response);
    if (tagMatch != null) {
      suggestions = _parseProductSuggestions(tagMatch.group(1)!.trim());
    }

    // Fallback: extract **bold product names** from the response text
    if (suggestions.isEmpty) {
      final boldRegex = RegExp(r'\*\*([^*]{3,60})\*\*');
      final names = boldRegex
          .allMatches(response)
          .map((m) => m.group(1)!.trim())
          .where((n) => !n.toLowerCase().contains('note') && !n.toLowerCase().contains('important'))
          .toList();
      suggestions = names
          .map((name) => <String, dynamic>{'name': name, 'query': name})
          .toList();
    }

    if (suggestions.isEmpty) return [];

    // Extract the budget across all suggestions (use the first non-zero value)
    double maxPriceInr = 0;
    for (final s in suggestions) {
      final raw = s['maxPriceInr'];
      if (raw != null) {
        final parsed = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString()) ?? 0;
        if (parsed > 0) { maxPriceInr = parsed; break; }
      }
    }

    try {
      final seenIds = <int>{};

      // Collect all candidate categories from suggestions (deduplicated)
      final categories = <String>[];
      for (final s in suggestions) {
        final cat = s['category']?.toString() ?? '';
        if (cat.isNotEmpty && !categories.contains(cat)) categories.add(cat);
      }

      // Also collect keyword-mapped fallback categories
      for (final s in suggestions) {
        final query = s['query']?.toString() ?? s['name']?.toString() ?? '';
        final lower = query.toLowerCase();
        for (final kw in _keywordToCategory.keys) {
          if (lower.contains(kw)) {
            final cat = _keywordToCategory[kw]!;
            if (!categories.contains(cat)) categories.add(cat);
            break;
          }
        }
      }

      // Fetch all products from each category (large limit so we have enough to filter)
      final allCandidates = <Product>[];
      for (final cat in categories) {
        final results = await ProductApiService.instance.fetchByCategory(cat, limit: 50);
        for (final p in results) {
          if (!seenIds.contains(p.id)) {
            seenIds.add(p.id);
            allCandidates.add(p);
          }
        }
      }

      // Apply price filter
      final filtered = maxPriceInr > 0
          ? allCandidates.where((p) => p.discountedPriceInr <= maxPriceInr).toList()
          : allCandidates;

      // Sort by relevance: if budget set, sort cheapest first; otherwise sort by rating
      if (maxPriceInr > 0) {
        filtered.sort((a, b) => a.discountedPriceInr.compareTo(b.discountedPriceInr));
      } else {
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      }

      return filtered.take(5).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> _buildQuickReplies(List<Product> products) {
    if (products.isNotEmpty) {
      return ['Add all to cart 🛒', 'Checkout 💳', 'Show more options', 'Start over'];
    }
    return ['Checkout my cart 🛒', 'Show categories', 'Start over'];
  }

  void addProductToCart(Product product) {
    _ref.read(cartProvider.notifier).addProduct(product);
  }

  void addAllToCart(List<Product> products) {
    for (final p in products) {
      _ref.read(cartProvider.notifier).addProduct(p);
    }
    ShoppingMemoryService.instance.recordPurchase(
      products.map((p) => p.title).toList(),
      products.map((p) => p.category).toList(),
    );
  }

  List<Map<String, dynamic>> _parseProductSuggestions(String raw) {
    // Strip markdown code fences if Gemini wraps in ```json ... ```
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Try proper JSON parse first
    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    // Fallback: extract individual JSON objects with regex
    final result = <Map<String, dynamic>>[];
    final objRegex = RegExp(r'\{[^{}]*\}', dotAll: true);
    for (final m in objRegex.allMatches(cleaned)) {
      try {
        final decoded = jsonDecode(m.group(0)!);
        if (decoded is Map) result.add(Map<String, dynamic>.from(decoded));
      } catch (_) {}
    }
    return result;
  }

  void clearChat() {
    GeminiService.instance.resetChat();
    state = [
      ChatMessage.assistant(
        "Chat cleared! What would you like to shop for?",
        quickReplies: ['Gaming mouse under ₹2000', 'Groceries for a week', 'Gift under ₹1500'],
      ),
    ];
  }
}


final aiAssistantProvider = StateNotifierProvider<AiAssistantNotifier, List<ChatMessage>>(
  (ref) => AiAssistantNotifier(ref),
);
