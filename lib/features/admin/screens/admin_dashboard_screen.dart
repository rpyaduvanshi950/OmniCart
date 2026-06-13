import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../orders/providers/orders_provider.dart';
import '../../../models/order_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ordersAsync.when(
        data: (orders) => _buildDashboard(context, orders),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<OrderModel> orders) {
    final revenue = orders.fold<double>(0, (s, o) => s + o.totalAmount);
    final delivered = orders.where((o) => o.status == OrderStatus.delivered).length;
    final pending = orders.where((o) => o.status == OrderStatus.ordered).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsRow(revenue, orders.length, delivered, pending),
        const SizedBox(height: 16),
        _buildManagementSection(context),
        const SizedBox(height: 16),
        _buildRevenueChart(orders),
        const SizedBox(height: 16),
        const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...orders.take(20).map((o) => _OrderTile(order: o)),
      ],
    );
  }

  Widget _buildStatsRow(double revenue, int total, int delivered, int pending) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _StatCard(label: 'Total Revenue', value: Formatters.currency(revenue), icon: Icons.currency_rupee, color: AppColors.primary),
          _StatCard(label: 'Total Orders', value: '$total', icon: Icons.shopping_bag_outlined, color: AppColors.accent),
          _StatCard(label: 'Delivered', value: '$delivered', icon: Icons.check_circle_outline, color: AppColors.success),
          _StatCard(label: 'Pending', value: '$pending', icon: Icons.hourglass_empty_outlined, color: AppColors.warning),
        ],
      );

  Widget _buildManagementSection(BuildContext context) => Row(
        children: [
          Expanded(
            child: _ManagementCard(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              subtitle: 'Add / Edit / Delete',
              color: AppColors.primary,
              onTap: () => context.push('/admin/products'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ManagementCard(
              icon: Icons.receipt_long_outlined,
              label: 'Orders',
              subtitle: 'Update Status',
              color: AppColors.accent,
              onTap: () => context.push('/admin/orders'),
            ),
          ),
        ],
      );

  Widget _buildRevenueChart(List<OrderModel> orders) {
    if (orders.isEmpty) return const SizedBox();

    final last7Days = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      final dayOrders = orders.where((o) =>
          o.createdAt.day == day.day && o.createdAt.month == day.month && o.createdAt.year == day.year);
      return FlSpot(i.toDouble(), dayOrders.fold<double>(0, (s, o) => s + o.totalAmount));
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue (Last 7 Days)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: last7Days,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ManagementCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = {
      OrderStatus.ordered: AppColors.warning,
      OrderStatus.packed: Colors.blue,
      OrderStatus.shipped: Colors.purple,
      OrderStatus.outForDelivery: AppColors.accent,
      OrderStatus.delivered: AppColors.success,
      OrderStatus.cancelled: AppColors.error,
    }[order.status] ?? AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.receipt_outlined, color: statusColor, size: 20),
        ),
        title: Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${order.items.length} item(s) • ${Formatters.dateTime(order.createdAt)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Formatters.currency(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(order.status.label, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
