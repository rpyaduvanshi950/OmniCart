import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/product_api_service.dart';
import '../../../models/product_model.dart';
import '../../../core/utils/formatters.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

final _giftProductsProvider = StateProvider<List<Product>>((_) => []);
final _isLoadingGiftsProvider = StateProvider<bool>((_) => false);

class GiftRecommendationScreen extends ConsumerStatefulWidget {
  const GiftRecommendationScreen({super.key});

  @override
  ConsumerState<GiftRecommendationScreen> createState() => _GiftRecommendationScreenState();
}

class _GiftRecommendationScreenState extends ConsumerState<GiftRecommendationScreen> {
  final _interestsCtrl = TextEditingController();
  double _budget = 2000;

  final _quickInterests = ['Cricket', 'Cooking', 'Gaming', 'Fitness', 'Music', 'Reading', 'Travel', 'Photography'];

  @override
  void dispose() {
    _interestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _recommend() async {
    if (_interestsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the person\'s interests')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(_isLoadingGiftsProvider.notifier).state = true;
    ref.read(_giftProductsProvider.notifier).state = [];

    final suggestions = await GeminiService.instance.suggestGifts(
      interests: _interestsCtrl.text.trim(),
      budget: _budget.round(),
    );

    if (!mounted) return;

    final products = <Product>[];
    for (final s in suggestions) {
      final results = await ProductApiService.instance.searchProducts(s, limit: 2);
      products.addAll(results.where((p) => p.discountedPriceInr <= _budget * 1.2));
      if (!mounted) return;
    }

    ref.read(_giftProductsProvider.notifier).state = products.take(8).toList();
    ref.read(_isLoadingGiftsProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(_giftProductsProvider);
    final isLoading = ref.watch(_isLoadingGiftsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Gift Recommendations')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildConfig()),
          if (isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (products.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _GiftCard(product: products[i]),
                  childCount: products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _interestsCtrl,
              decoration: const InputDecoration(
                labelText: 'Recipient\'s Interests',
                hintText: 'e.g. cricket-loving father, tech enthusiast sister',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Budget: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(Formatters.currency(_budget), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _budget,
              min: 200,
              max: 20000,
              divisions: 99,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _budget = v),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _quickInterests.map((interest) => ActionChip(
                label: Text(interest, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  final current = _interestsCtrl.text.trim();
                  _interestsCtrl.text = current.isEmpty ? interest : '$current, $interest';
                },
              )).toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _recommend,
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Find Gifts'),
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
              'Finding perfect gifts under ${Formatters.currency(_budget)}...',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 80, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('Find perfect gifts', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            SizedBox(height: 8),
            Text('Enter interests and budget above', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _GiftCard extends ConsumerWidget {
  final Product product;
  const _GiftCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inWishlist = ref.watch(wishlistProvider).any((p) => p.id == product.id);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: product.thumbnail,
                    width: double.infinity, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppColors.border, child: const Icon(Icons.image, size: 40)),
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => ref.read(wishlistProvider.notifier).toggle(product),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(inWishlist ? Icons.favorite : Icons.favorite_outline, size: 16, color: inWishlist ? AppColors.secondary : AppColors.textSecondary),
                    ),
                  ),
                ),
                Positioned(
                  top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Gift', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(Formatters.currency(product.discountedPriceInr), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gift added to cart!'), duration: Duration(seconds: 1)),
                      );
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                    child: const Text('Add to Cart', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
