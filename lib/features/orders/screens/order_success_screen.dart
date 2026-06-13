import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 32),
              const Text('Order Placed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Your order has been placed successfully.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Order ID: ${orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              _buildTrackingSteps(),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                child: const Text('Continue Shopping'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/orders/$orderId'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                child: const Text('Track Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingSteps() {
    final steps = ['Ordered', 'Packed', 'Shipped', 'Out for Delivery', 'Delivered'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) return Expanded(child: Container(height: 2, color: i == 1 ? AppColors.primary : AppColors.border));
        final stepIndex = i ~/ 2;
        final isActive = stepIndex == 0;
        return Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: isActive ? Colors.white : AppColors.textSecondary, size: 14),
            ),
            const SizedBox(height: 4),
            Text(steps[stepIndex], style: TextStyle(fontSize: 9, color: isActive ? AppColors.primary : AppColors.textSecondary)),
          ],
        );
      }),
    );
  }
}
