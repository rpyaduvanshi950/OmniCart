import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/gemini_service.dart';

final _comparisonResultProvider = StateProvider<String?>((_) => null);
final _isComparingProvider = StateProvider<bool>((_) => false);

class ProductComparisonScreen extends ConsumerStatefulWidget {
  const ProductComparisonScreen({super.key});

  @override
  ConsumerState<ProductComparisonScreen> createState() => _ProductComparisonScreenState();
}

class _ProductComparisonScreenState extends ConsumerState<ProductComparisonScreen> {
  final _product1Ctrl = TextEditingController();
  final _product2Ctrl = TextEditingController();

  final _suggestions = [
    ['iPhone 15', 'Samsung Galaxy S24'],
    ['MacBook Air', 'Dell XPS 15'],
    ['Sony WH-1000XM5', 'Bose QC45'],
    ['Nike Air Max', 'Adidas Ultraboost'],
  ];

  @override
  void dispose() {
    _product1Ctrl.dispose();
    _product2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    final p1 = _product1Ctrl.text.trim();
    final p2 = _product2Ctrl.text.trim();
    if (p1.isEmpty || p2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both products to compare')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(_comparisonResultProvider.notifier).state = null;
    ref.read(_isComparingProvider.notifier).state = true;
    final result = await GeminiService.instance.compareProducts(p1, p2);
    ref.read(_comparisonResultProvider.notifier).state = result;
    ref.read(_isComparingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(_comparisonResultProvider);
    final isComparing = ref.watch(_isComparingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Product Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(_comparisonResultProvider.notifier).state = null;
              _product1Ctrl.clear();
              _product2Ctrl.clear();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildInputSection(),
          const SizedBox(height: 16),
          _buildSuggestions(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isComparing ? null : _compare,
            icon: isComparing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.compare_arrows),
            label: Text(isComparing ? 'Comparing...' : 'Compare with AI'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          if (result != null) ...[
            const SizedBox(height: 24),
            _buildResult(result),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.compare_arrows, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Smart Comparison', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Gemini analyses specs, price & reviews', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildInputSection() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _product1Ctrl,
              decoration: const InputDecoration(
                labelText: 'Product 1',
                hintText: 'e.g. iPhone 15',
                prefixIcon: Icon(Icons.looks_one_outlined),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Text('VS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _product2Ctrl,
              decoration: const InputDecoration(
                labelText: 'Product 2',
                hintText: 'e.g. Samsung S24',
                prefixIcon: Icon(Icons.looks_two_outlined),
              ),
            ),
          ),
        ],
      );

  Widget _buildSuggestions() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Compare:', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((pair) => ActionChip(
              label: Text('${pair[0]} vs ${pair[1]}', style: const TextStyle(fontSize: 12)),
              onPressed: () {
                _product1Ctrl.text = pair[0];
                _product2Ctrl.text = pair[1];
              },
            )).toList(),
          ),
        ],
      );

  Widget _buildResult(String result) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(gradient: AppColors.gradientPrimary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('AI Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(result, style: const TextStyle(height: 1.6, color: AppColors.textPrimary)),
            ],
          ),
        ),
      );
}
