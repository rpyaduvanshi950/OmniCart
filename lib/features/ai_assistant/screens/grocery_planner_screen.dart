import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/product_api_service.dart';
import '../../cart/providers/cart_provider.dart';

final _groceryListProvider = StateProvider<List<String>>((_) => []);
final _isGeneratingProvider = StateProvider<bool>((_) => false);
final _checkedItemsProvider = StateProvider<Set<String>>((_) => {});

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
    ref.read(_groceryListProvider.notifier).state = [];
    ref.read(_checkedItemsProvider.notifier).state = {};
    final items = await GeminiService.instance.generateGroceryList(
      familySize: _familySize,
      weeks: _weeks,
    );
    ref.read(_groceryListProvider.notifier).state = items;
    ref.read(_isGeneratingProvider.notifier).state = false;
  }

  Future<void> _addCheckedToCart() async {
    final checked = ref.read(_checkedItemsProvider);
    final allItems = ref.read(_groceryListProvider);
    final toAdd = checked.isEmpty ? allItems : allItems.where((i) => checked.contains(i)).toList();

    int added = 0;
    for (final item in toAdd) {
      final products = await ProductApiService.instance.searchProducts(item, limit: 1);
      if (products.isNotEmpty) {
        ref.read(cartProvider.notifier).addProduct(products.first);
        added++;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $added grocery items to cart'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groceries = ref.watch(_groceryListProvider);
    final isGenerating = ref.watch(_isGeneratingProvider);
    final checked = ref.watch(_checkedItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Grocery Planner'),
        actions: [
          if (groceries.isNotEmpty)
            TextButton.icon(
              onPressed: _addCheckedToCart,
              icon: const Icon(Icons.shopping_cart_outlined, size: 18),
              label: Text(checked.isEmpty ? 'Add All' : 'Add ${checked.length}'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildConfig(),
          Expanded(
            child: isGenerating
                ? _buildLoadingState()
                : groceries.isEmpty
                    ? _buildEmptyState()
                    : _buildGroceryList(groceries, checked),
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

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('No grocery list yet', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            const Text('Configure and tap Generate to create\nyour personalized grocery list', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _buildGroceryList(List<String> items, Set<String> checked) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${items.length} items', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                TextButton(
                  onPressed: () => ref.read(_checkedItemsProvider.notifier).state =
                      checked.length == items.length ? {} : Set.from(items),
                  child: Text(checked.length == items.length ? 'Deselect All' : 'Select All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isChecked = checked.contains(item);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: isChecked,
                    onChanged: (_) {
                      final newSet = Set<String>.from(checked);
                      if (isChecked) {
                        newSet.remove(item);
                      } else {
                        newSet.add(item);
                      }
                      ref.read(_checkedItemsProvider.notifier).state = newSet;
                    },
                    title: Text(item, style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : null, color: isChecked ? AppColors.textSecondary : null)),
                    secondary: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.eco_outlined, color: AppColors.accent, size: 16),
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
