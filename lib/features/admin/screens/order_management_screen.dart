import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../orders/providers/orders_provider.dart';

class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Management')),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No orders yet', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (_, i) => _OrderManagementTile(order: orders[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OrderManagementTile extends StatelessWidget {
  final OrderModel order;
  const _OrderManagementTile({required this.order});

  static const _statusColors = {
    OrderStatus.ordered: AppColors.warning,
    OrderStatus.packed: Colors.blue,
    OrderStatus.shipped: Colors.purple,
    OrderStatus.outForDelivery: AppColors.accent,
    OrderStatus.delivered: AppColors.success,
    OrderStatus.cancelled: AppColors.error,
  };

  Future<void> _updateStatus(BuildContext context, OrderStatus newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(order.id).update({'status': newStatus.name});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order updated to: ${newStatus.label}'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...OrderStatus.values.where((s) => s != OrderStatus.cancelled).map((status) {
              final color = _statusColors[status] ?? AppColors.textSecondary;
              final isCurrent = order.status == status;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(
                    [Icons.shopping_bag, Icons.inventory, Icons.local_shipping, Icons.delivery_dining, Icons.check_circle][status.step],
                    color: color, size: 20,
                  ),
                ),
                title: Text(status.label, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                trailing: isCurrent ? const Icon(Icons.check, color: AppColors.success) : null,
                onTap: isCurrent ? null : () {
                  Navigator.pop(context);
                  _updateStatus(context, status);
                },
              );
            }),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
              ),
              title: const Text('Cancel Order'),
              onTap: () {
                Navigator.pop(context);
                _updateStatus(context, OrderStatus.cancelled);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[order.status] ?? AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(Icons.receipt_outlined, color: statusColor, size: 20),
        ),
        title: Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Formatters.dateTime(order.createdAt), style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(order.status.label, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        trailing: Text(Formatters.currency(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text('Order Items:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...order.items.map((item) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.product.title} × ${item.quantity}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                    Text(Formatters.currency(item.totalPriceInr), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                )),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(order.address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.payment_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(order.paymentMethod, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusPicker(context),
                    icon: const Icon(Icons.update, size: 18),
                    label: const Text('Update Status'),
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
