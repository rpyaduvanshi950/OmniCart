import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../features/profile/screens/profile_screen.dart';

// Bridges Firebase auth stream → GoRouter refresh
class _AuthRefreshStream extends ChangeNotifier {
  _AuthRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authRefresh = _AuthRefreshStream(FirebaseAuth.instance.authStateChanges());

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: _authRefresh,
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;

    final isAuthRoute = loc == '/login' || loc == '/register' || loc == '/verify-email';

    // Not logged in and trying to access a protected page → send to login
    if (!isLoggedIn && !isAuthRoute) return '/login';

    // Already logged in and still on auth pages → go home
    if (isLoggedIn && isAuthRoute) return '/home';

    return null; // no redirect needed
  },
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
