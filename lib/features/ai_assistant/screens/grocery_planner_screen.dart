import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/product_api_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';

final _groceryProductsProvider = StateProvider<List<Product>>((_) => []);
final _selectedIdsProvider = StateProvider<Set<int>>((_) => {});
final _isGeneratingProvider = StateProvider<bool>((_) => false);

class GroceryPlannerScreen extends ConsumerStatefulWidget {
  const GroceryPlannerScreen({super.key});

  @override
  ConsumerState<GroceryPlannerScreen> createState() => _GroceryPlannerScreenState();
}

class _GroceryPlannerScreenState extends ConsumerState<GroceryPlannerScreen> {
  int _familySize = 4;
  int _weeks = 1;

  Future<void> _generate() async {
    ref.read(_isGeneratingProvider.notifier).state = true;
    ref.read(_groceryProductsProvider.notifier).state = [];
    ref.read(_selectedIdsProvider.notifier).state = {};

    // Fetch all available grocery products from DummyJSON catalog
    final catalog = await ProductApiService.instance.fetchByCategory('groceries', limit: 50);

    if (!mounted) return;

    // Ask AI to pick the right ones for this family/duration from the actual catalog
    final selectedNames = await GeminiService.instance.generateGroceryList(
      familySize: _familySize,
      weeks: _weeks,
      availableProducts: catalog.map((p) => p.title).toList(),
    );

    if (!mounted) return;

    // Match AI-selected names to actual Product objects (case-insensitive)
    final selectedLower = selectedNames.map((n) => n.toLowerCase()).toSet();
    final matched = catalog.where((p) => selectedLower.contains(p.title.toLowerCase())).toList();

    // Fall back to full catalog if AI returned nothing recognisable
    final products = matched.isNotEmpty ? matched : catalog;

    ref.read(_groceryProductsProvider.notifier).state = products;
    // Pre-select all recommended products
    ref.read(_selectedIdsProvider.notifier).state = products.map((p) => p.id).toSet();
    ref.read(_isGeneratingProvider.notifier).state = false;
  }

  void _addSelectedToCart() {
    final products = ref.read(_groceryProductsProvider);
    final selected = ref.read(_selectedIdsProvider);
    final toAdd = products.where((p) => selected.contains(p.id)).toList();

    for (final p in toAdd) {
      ref.read(cartProvider.notifier).addProduct(p);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${toAdd.length} grocery item${toAdd.length == 1 ? '' : 's'} to cart'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(_groceryProductsProvider);
    final selected = ref.watch(_selectedIdsProvider);
    final isGenerating = ref.watch(_isGeneratingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Grocery Planner'),
        actions: [
          if (products.isNotEmpty && selected.isNotEmpty)
            TextButton.icon(
              onPressed: _addSelectedToCart,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text('Add ${selected.length}'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildConfig(),
          Expanded(
            child: isGenerating
                ? _buildLoadingState()
                : products.isEmpty
                    ? _buildEmptyState()
                    : _buildProductList(products, selected),
          ),
        ],
      ),
    );
  }

  Widget _buildConfig() => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Family Size', style: TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _familySize > 1 ? () => setState(() => _familySize--) : null,
                          ),
                          Text('$_familySize', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _familySize < 10 ? () => setState(() => _familySize++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _weeks > 1 ? () => setState(() => _weeks--) : null,
                          ),
                          Text('$_weeks week${_weeks > 1 ? 's' : ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _weeks < 4 ? () => setState(() => _weeks++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Grocery List'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
            ),
          ],
        ),
      );

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'AI is planning groceries for $_familySize people\nfor $_weeks week${_weeks > 1 ? 's' : ''}...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('No grocery list yet', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text(
              'Configure and tap Generate to create\nyour personalized grocery list',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _buildProductList(List<Product> products, Set<int> selected) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${products.length} items', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              TextButton(
                onPressed: () {
                  final allSelected = selected.length == products.length;
                  ref.read(_selectedIdsProvider.notifier).state =
                      allSelected ? {} : products.map((p) => p.id).toSet();
                },
                child: Text(selected.length == products.length ? 'Deselect All' : 'Select All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final product = products[i];
              final isSelected = selected.contains(product.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) {
                    final newSet = Set<int>.from(selected);
                    if (isSelected) {
                      newSet.remove(product.id);
                    } else {
                      newSet.add(product.id);
                    }
                    ref.read(_selectedIdsProvider.notifier).state = newSet;
                  },
                  title: Text(
                    product.title,
                    style: TextStyle(
                      decoration: isSelected ? null : TextDecoration.none,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    Formatters.currency(product.discountedPriceInr),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  secondary: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.thumbnail,
                      width: 48, height: 48, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 48, height: 48,
                        color: AppColors.border,
                        child: const Icon(Icons.eco_outlined, color: AppColors.accent, size: 20),
                      ),
                    ),
                  ),
                  activeColor: AppColors.primary,
                  dense: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
