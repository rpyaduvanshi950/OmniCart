import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/gemini_service.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../providers/products_provider.dart';

final _reviewSummaryProvider = StateProvider.family<String?, int>((_,  __) => null);
final _summaryLoadingProvider = StateProvider.family<bool, int>((_, __) => false);

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImage = 0;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return productAsync.when(
      data: (product) {
        if (product == null) return const Scaffold(body: Center(child: Text('Product not found')));

        final inWishlist = ref.watch(wishlistProvider.notifier).contains(product.id);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(inWishlist ? Icons.favorite : Icons.favorite_outline, color: inWishlist ? AppColors.secondary : null),
                    onPressed: () => ref.read(wishlistProvider.notifier).toggle(product),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    children: [
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: product.images.isNotEmpty ? product.images[_selectedImage] : product.thumbnail,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorWidget: (_, __, ___) => Container(color: AppColors.border, child: const Icon(Icons.image, size: 64)),
                        ),
                      ),
                      if (product.images.length > 1)
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: product.images.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => setState(() => _selectedImage = i),
                              child: Container(
                                width: 44,
                                decoration: BoxDecoration(
                                  border: Border.all(color: _selectedImage == i ? AppColors.primary : Colors.transparent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(imageUrl: product.images[i], fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: product.rating,
                            itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.warning),
                            itemCount: 5, itemSize: 16,
                          ),
                          const SizedBox(width: 8),
                          Text('${product.rating} / 5.0', style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isInStock ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.isInStock ? 'In Stock (${product.stock})' : 'Out of Stock',
                              style: TextStyle(color: product.isInStock ? AppColors.success : AppColors.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(Formatters.currency(product.discountedPriceInr), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          if (product.discountPercentage > 0) ...[
                            const SizedBox(width: 8),
                            Text(Formatters.currency(product.priceInr), style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                              child: Text('${product.discountPercentage.round()}% OFF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(product.description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.category_outlined, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Category: ${product.category}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReviewSummarySection(productId: product.id, productTitle: product.title, rating: product.rating),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: product.isInStock
                        ? () {
                            ref.read(wishlistProvider.notifier).toggle(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(inWishlist ? 'Removed from wishlist' : 'Added to wishlist'), duration: const Duration(seconds: 1)),
                            );
                          }
                        : null,
                    icon: Icon(inWishlist ? Icons.favorite : Icons.favorite_outline),
                    label: const Text('Wishlist'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: product.isInStock
                        ? () {
                            ref.read(cartProvider.notifier).addProduct(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart'), duration: Duration(seconds: 1)),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _ReviewSummarySection extends ConsumerWidget {
  final int productId;
  final String productTitle;
  final double rating;

  const _ReviewSummarySection({required this.productId, required this.productTitle, required this.rating});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(_reviewSummaryProvider(productId));
    final isLoading = ref.watch(_summaryLoadingProvider(productId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                    SizedBox(width: 6),
                    Text('AI Review Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                if (summary == null && !isLoading)
                  TextButton(
                    onPressed: () async {
                      ref.read(_summaryLoadingProvider(productId).notifier).state = true;
                      // Generate synthetic reviews based on rating for demo
                      final syntheticReviews = _generateSyntheticReviews(productTitle, rating);
                      final result = await GeminiService.instance.summarizeReviews(syntheticReviews);
                      ref.read(_reviewSummaryProvider(productId).notifier).state = result;
                      ref.read(_summaryLoadingProvider(productId).notifier).state = false;
                    },
                    child: const Text('Summarize Reviews'),
                  ),
              ],
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    SizedBox(width: 10),
                    Text('AI is analysing reviews...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else if (summary != null) ...[
              const SizedBox(height: 8),
              Text(summary, style: const TextStyle(color: AppColors.textPrimary, height: 1.5)),
            ] else
              const Text('Tap "Summarize Reviews" to get an AI-powered summary of customer feedback.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  List<String> _generateSyntheticReviews(String productName, double rating) {
    final positive = [
      'Great product, very happy with the quality.',
      'Excellent build and fast delivery.',
      'Works perfectly, highly recommend.',
      'Good value for money.',
      'Amazing quality, would buy again.',
    ];
    final negative = [
      'Packaging could be better.',
      'Took a while to deliver.',
      'Slightly different from photos.',
    ];
    final count = (rating * 2).round();
    return [...positive.take(count), ...negative.take(5 - count)];
  }
}
