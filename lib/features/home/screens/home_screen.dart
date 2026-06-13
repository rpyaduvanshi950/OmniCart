import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../products/providers/products_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _HomeTab(),
          _buildCartTab(),
          _buildWishlistTab(),
          _buildOrdersTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ai-chat'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        label: const Text('AI Shop', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: badges.Badge(
              showBadge: cartCount > 0,
              badgeContent: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: badges.Badge(
              showBadge: cartCount > 0,
              badgeContent: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'Wishlist'),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCartTab() {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    if (items.isEmpty) {
      return const Scaffold(
        appBar: _SimpleAppBar(title: 'Cart'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text('Your cart is empty', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const _SimpleAppBar(title: 'Cart'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.product.thumbnail,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 72, height: 72, color: AppColors.border, child: const Icon(Icons.image)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(Formatters.currency(item.product.discountedPriceInr), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1),
                      ),
                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total', style: TextStyle(color: AppColors.textSecondary)),
                Text(Formatters.currency(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                child: const Text('Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistTab() {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: const _SimpleAppBar(title: 'Wishlist'),
      body: wishlist.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 80, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Your wishlist is empty', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: wishlist.length,
              itemBuilder: (_, i) => _ProductCard(product: wishlist[i]),
            ),
    );
  }

  Widget _buildOrdersTab() => _OrdersTab(onShop: () => setState(() => _currentIndex = 0));

  Widget _buildProfileTab() => const ProfileScreen();
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final category = ref.watch(selectedCategoryProvider);
    final categories = ref.watch(categoriesProvider);

    final productsAsync = query.isNotEmpty
        ? ref.watch(productSearchProvider(query))
        : category != null
            ? ref.watch(productsByCategoryProvider(category))
            : ref.watch(allProductsProvider(0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniCart'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildBanner()),
          SliverToBoxAdapter(
            child: categories.when(
              data: (cats) => _buildCategories(cats),
              loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    query.isNotEmpty ? 'Search Results' : category != null ? category.toUpperCase() : 'Featured Products',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (category != null)
                    TextButton(
                      onPressed: () => ref.read(selectedCategoryProvider.notifier).state = null,
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
          ),
          productsAsync.when(
            data: (products) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ProductCard(product: products[i]),
                  childCount: products.length,
                ),
              ),
            ),
            loading: () => SliverToBoxAdapter(child: _buildShimmer()),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onSubmitted: (v) => ref.read(searchQueryProvider.notifier).state = v.trim(),
          onChanged: (v) {
            if (v.isEmpty) ref.read(searchQueryProvider.notifier).state = '';
          },
        ),
      );

  Widget _buildBanner() => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Shop with AI', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Just describe what you need!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.push('/ai-chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Try AI Shopping', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.smart_toy_outlined, color: Colors.white38, size: 64),
          ],
        ),
      );

  Widget _buildCategories(List<String> cats) => SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final selected = ref.watch(selectedCategoryProvider) == cats[i];
            return FilterChip(
              label: Text(cats[i]),
              selected: selected,
              onSelected: (_) {
                ref.read(selectedCategoryProvider.notifier).state = selected ? null : cats[i];
                ref.read(searchQueryProvider.notifier).state = '';
              },
            );
          },
        ),
      );

  Widget _buildShimmer() => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: 6,
          itemBuilder: (_, __) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        ),
      );
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inWishlist = ref.watch(wishlistProvider.notifier).contains(product.id);

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Card(
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
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: AppColors.border, child: const Icon(Icons.image, size: 48)),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => ref.read(wishlistProvider.notifier).toggle(product),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(inWishlist ? Icons.favorite : Icons.favorite_outline, size: 18, color: inWishlist ? AppColors.secondary : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                        child: Text('${product.discountPercentage.round()}% OFF', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                  Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: product.rating,
                        itemBuilder: (_, __) => const Icon(Icons.star, color: AppColors.warning),
                        itemCount: 5, itemSize: 12,
                      ),
                      const SizedBox(width: 4),
                      Text('${product.rating}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(Formatters.currency(product.discountedPriceInr), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  if (product.discountPercentage > 0)
                    Text(Formatters.currency(product.priceInr), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, decoration: TextDecoration.lineThrough)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: product.isInStock
                          ? () {
                              ref.read(cartProvider.notifier).addProduct(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${product.title} added to cart'), duration: const Duration(seconds: 1)),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                      child: Text(product.isInStock ? 'Add to Cart' : 'Out of Stock', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _SimpleAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: Text(title));
}

// ─── Orders tab ───────────────────────────────────────────────────────────────

class _OrdersTab extends ConsumerWidget {
  final VoidCallback onShop;
  const _OrdersTab({required this.onShop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const _SimpleAppBar(title: 'My Orders'),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading orders: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No orders yet', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: onShop, child: const Text('Start Shopping')),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg) = switch (order.status) {
      OrderStatus.ordered => (AppColors.primary, AppColors.primary.withValues(alpha: 0.1)),
      OrderStatus.packed => (Colors.orange, Colors.orange.withValues(alpha: 0.1)),
      OrderStatus.shipped => (Colors.blue, Colors.blue.withValues(alpha: 0.1)),
      OrderStatus.outForDelivery => (Colors.deepOrange, Colors.deepOrange.withValues(alpha: 0.1)),
      OrderStatus.delivered => (AppColors.success, AppColors.success.withValues(alpha: 0.1)),
      OrderStatus.cancelled => (AppColors.error, AppColors.error.withValues(alpha: 0.1)),
    };

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(order.status.label,
                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(Formatters.dateTime(order.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              // Item thumbnails
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    ...order.items.take(4).map((item) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              item.product.thumbnail,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                              ),
                            ),
                          ),
                        )),
                    if (order.items.length > 4)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text('+${order.items.length - 4}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.items.length} item${order.items.length > 1 ? "s" : ""}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(Formatters.currency(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 10),
              // Compact tracking bar
              if (order.status != OrderStatus.cancelled)
                _MiniTrackBar(status: order.status),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Tap to track →',
                    style: TextStyle(fontSize: 11, color: AppColors.primary.withValues(alpha: 0.7))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTrackBar extends StatelessWidget {
  final OrderStatus status;
  const _MiniTrackBar({required this.status});

  @override
  Widget build(BuildContext context) {
    const labels = ['Ordered', 'Packed', 'Shipped', 'Delivery', 'Done'];
    final step = status.step;
    return Row(
      children: List.generate(5 * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < step ? AppColors.primary : Colors.grey.shade200,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx < step;
        final active = idx == step;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.primary
                    : active
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                    color: done || active ? AppColors.primary : Colors.grey.shade300, width: 1.5),
              ),
              child: done
                  ? const Icon(Icons.check, color: Colors.white, size: 8)
                  : active
                      ? Center(
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                        )
                      : null,
            ),
            const SizedBox(height: 3),
            Text(labels[idx],
                style: TextStyle(
                    fontSize: 8,
                    color: done || active ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        );
      }),
    );
  }
}


