import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/email_verification_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/ai_assistant/screens/ai_chat_screen.dart';
import '../features/ai_assistant/screens/product_comparison_screen.dart';
import '../features/ai_assistant/screens/grocery_planner_screen.dart';
import '../features/ai_assistant/screens/gift_recommendation_screen.dart';
import '../features/checkout/screens/checkout_screen.dart';
import '../features/orders/screens/order_success_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/product_management_screen.dart';
import '../features/admin/screens/order_management_screen.dart';
import '../features/profile/screens/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/verify-email', builder: (_, __) => const EmailVerificationScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(
      path: '/product/:id',
      builder: (_, state) => ProductDetailScreen(productId: int.parse(state.pathParameters['id']!)),
    ),
    // AI Tools
    GoRoute(path: '/ai-chat', builder: (_, __) => const AiChatScreen()),
    GoRoute(path: '/compare', builder: (_, __) => const ProductComparisonScreen()),
    GoRoute(path: '/grocery-planner', builder: (_, __) => const GroceryPlannerScreen()),
    GoRoute(path: '/gift-recommendations', builder: (_, __) => const GiftRecommendationScreen()),
    // Checkout & Orders
    GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
    GoRoute(
      path: '/order-success/:id',
      builder: (_, state) => OrderSuccessScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
    ),
    // Admin
    GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
    GoRoute(path: '/admin/products', builder: (_, __) => const ProductManagementScreen()),
    GoRoute(path: '/admin/orders', builder: (_, __) => const OrderManagementScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Reset Password')),
        body: const Center(child: Text('Password reset email sent!')),
      ),
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);
