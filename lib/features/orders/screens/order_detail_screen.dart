import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';

final _orderDetailProvider = StreamProvider.family<OrderModel?, String>((ref, id) {
  return FirebaseFirestore.instance
      .collection('orders')
      .doc(id)
      .snapshots()
      .map((snap) => snap.exists ? OrderModel.fromMap(snap.data()!) : null);
});

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('#${orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TrackingCard(status: order.status),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Delivery Address',
                icon: Icons.location_on_outlined,
                child: Text(order.address, style: const TextStyle(fontSize: 13, height: 1.5)),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Payment',
                icon: Icons.payment_outlined,
                child: Row(
                  children: [
                    Icon(
                      order.paymentMethod == 'COD' ? Icons.money_rounded : Icons.credit_card_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.paymentMethod == 'COD' ? 'Cash on Delivery' : 'Online Payment',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Items Ordered',
                icon: Icons.shopping_bag_outlined,
                child: Column(
                  children: [
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.product.thumbnail,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.title,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    Text('Qty: ${item.quantity}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text(Formatters.currency(item.totalPriceInr),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        )),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(Formatters.currency(order.totalAmount),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Order Info',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    _row('Order ID', '#${orderId.substring(0, 8).toUpperCase()}'),
                    _row('Placed On', Formatters.dateTime(order.createdAt)),
                    _row('Status', order.status.label),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}

// ─── Tracking timeline ────────────────────────────────────────────────────────

class _TrackingCard extends StatelessWidget {
  final OrderStatus status;
  const _TrackingCard({required this.status});

  static const _steps = [
    (Icons.check_circle_outline, 'Ordered'),
    (Icons.inventory_2_outlined, 'Packed'),
    (Icons.local_shipping_outlined, 'Shipped'),
    (Icons.delivery_dining_outlined, 'Out for Delivery'),
    (Icons.home_outlined, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = status == OrderStatus.cancelled ? -1 : status.step;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Order Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 20),
            if (status == OrderStatus.cancelled)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('This order has been cancelled',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            else
              Column(
                children: List.generate(_steps.length * 2 - 1, (i) {
                  if (i.isOdd) {
                    final stepIdx = i ~/ 2;
                    final done = currentStep > stepIdx;
                    return Container(
                      margin: const EdgeInsets.only(left: 13),
                      width: 2,
                      height: 28,
                      color: done ? AppColors.primary : Colors.grey.shade200,
                    );
                  }
                  final stepIdx = i ~/ 2;
                  final done = currentStep > stepIdx;
                  final active = currentStep == stepIdx;
                  final (icon, label) = _steps[stepIdx];
                  return Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.primary
                              : active
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done || active ? AppColors.primary : Colors.grey.shade300,
                            width: active ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          done ? Icons.check_rounded : icon,
                          size: 14,
                          color: done
                              ? Colors.white
                              : active
                                  ? AppColors.primary
                                  : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active || done ? FontWeight.w600 : FontWeight.normal,
                          color: active || done ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Current',
                              style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      OrderStatus.ordered => (AppColors.primary, AppColors.primary.withValues(alpha: 0.1)),
      OrderStatus.packed => (Colors.orange, Colors.orange.withValues(alpha: 0.1)),
      OrderStatus.shipped => (Colors.blue, Colors.blue.withValues(alpha: 0.1)),
      OrderStatus.outForDelivery => (Colors.deepOrange, Colors.deepOrange.withValues(alpha: 0.1)),
      OrderStatus.delivered => (AppColors.success, AppColors.success.withValues(alpha: 0.1)),
      OrderStatus.cancelled => (AppColors.error, AppColors.error.withValues(alpha: 0.1)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _InfoCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}
