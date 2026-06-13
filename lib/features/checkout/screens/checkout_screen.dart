import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/shopping_memory_service.dart';
import '../../../models/user_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/orders_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> with TickerProviderStateMixin {
  // Steps: 0 = address, 1 = payment, 2 = review+place
  int _step = 0;
  late final PageController _pageCtrl;

  // Address state
  List<DeliveryAddress> _savedAddresses = [];
  int? _selectedSavedIdx;
  bool _addingNew = false;
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  // Payment state
  String _paymentMethod = 'COD'; // 'COD' or 'PREPAY'

  bool _isPlacing = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _checkAuth();
    _loadAddresses();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _labelCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    if (FirebaseAuth.instance.currentUser == null && mounted) {
      final go = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You need to be logged in to place an order.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Login')),
          ],
        ),
      );
      if (!mounted) return;
      if (go == true) {
        context.push('/login');
      } else {
        context.pop();
      }
    }
  }

  Future<void> _loadAddresses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    final raw = (doc.data()?['savedAddresses'] as List?) ?? [];
    final addresses = raw.map((e) => DeliveryAddress.fromMap(e)).toList();
    setState(() {
      _savedAddresses = addresses;
      if (addresses.isNotEmpty) {
        _selectedSavedIdx = 0;
        _fillForm(addresses[0]);
      } else {
        _addingNew = true;
      }
    });
  }

  void _fillForm(DeliveryAddress addr) {
    _labelCtrl.text = addr.label;
    _nameCtrl.text = addr.name;
    _phoneCtrl.text = addr.phone;
    _addressCtrl.text = addr.address;
    _cityCtrl.text = addr.city;
    _pincodeCtrl.text = addr.pincode;
  }

  void _clearForm() {
    _labelCtrl.clear();
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _addressCtrl.clear();
    _cityCtrl.clear();
    _pincodeCtrl.clear();
  }

  Future<void> _saveNewAddressIfNeeded() async {
    if (!_addingNew) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final newAddr = DeliveryAddress(
      label: _labelCtrl.text.trim().isEmpty ? 'Address ${_savedAddresses.length + 1}' : _labelCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
    );
    final updated = [..._savedAddresses, newAddr];
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'savedAddresses': updated.map((a) => a.toMap()).toList(),
    });
    setState(() {
      _savedAddresses = updated;
      _selectedSavedIdx = updated.length - 1;
      _addingNew = false;
    });
  }

  bool _addressIsValid() {
    return _nameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _addressCtrl.text.trim().isNotEmpty &&
        _cityCtrl.text.trim().isNotEmpty &&
        _pincodeCtrl.text.trim().isNotEmpty;
  }

  void _goToStep(int s) {
    setState(() => _step = s);
    _pageCtrl.animateToPage(s, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    final items = ref.read(cartProvider);
    final address =
        '${_nameCtrl.text}, ${_phoneCtrl.text}, ${_addressCtrl.text}, ${_cityCtrl.text} - ${_pincodeCtrl.text}';

    try {
      final placeOrder = ref.read(placeOrderProvider);
      final orderId = await placeOrder(items, address, _paymentMethod);
      await ShoppingMemoryService.instance.recordPurchase(
        items.map((i) => i.product.title).toList(),
        items.map((i) => i.product.category).toList(),
      );
      ref.read(cartProvider.notifier).clear();
      if (mounted) context.go('/order-success/$orderId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final deliveryFee = total > 499 ? 0.0 : 49.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Checkout'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _StepIndicator(current: _step),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _AddressStep(
            savedAddresses: _savedAddresses,
            selectedIdx: _selectedSavedIdx,
            addingNew: _addingNew,
            formKey: _formKey,
            labelCtrl: _labelCtrl,
            nameCtrl: _nameCtrl,
            phoneCtrl: _phoneCtrl,
            addressCtrl: _addressCtrl,
            cityCtrl: _cityCtrl,
            pincodeCtrl: _pincodeCtrl,
            onSelectSaved: (i) {
              setState(() {
                _selectedSavedIdx = i;
                _addingNew = false;
                _fillForm(_savedAddresses[i]);
              });
            },
            onAddNew: () {
              setState(() {
                _selectedSavedIdx = null;
                _addingNew = true;
                _clearForm();
              });
            },
            onNext: () async {
              if (_addingNew && !(_formKey.currentState?.validate() ?? false)) return;
              await _saveNewAddressIfNeeded();
              if (mounted) _goToStep(1);
            },
          ),
          _PaymentStep(
            selected: _paymentMethod,
            onSelect: (v) => setState(() => _paymentMethod = v),
            onBack: () => _goToStep(0),
            onNext: () => _goToStep(2),
          ),
          _ReviewStep(
            items: items,
            total: total,
            deliveryFee: deliveryFee,
            address: _addressIsValid()
                ? '${_nameCtrl.text}\n${_phoneCtrl.text}\n${_addressCtrl.text}, ${_cityCtrl.text} - ${_pincodeCtrl.text}'
                : '',
            paymentMethod: _paymentMethod,
            isPlacing: _isPlacing,
            onBack: () => _goToStep(1),
            onPlace: _placeOrder,
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    const steps = ['Address', 'Payment', 'Review'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = current > i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? AppColors.primary : Colors.grey.shade200,
              ),
            );
          }
          final idx = i ~/ 2;
          final done = current > idx;
          final active = current == idx;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done || active ? AppColors.primary : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text('${idx + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: active ? Colors.white : Colors.grey)),
                ),
              ),
              const SizedBox(height: 3),
              Text(steps[idx],
                  style: TextStyle(
                      fontSize: 10,
                      color: active ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Address ──────────────────────────────────────────────────────────

class _AddressStep extends StatelessWidget {
  final List<DeliveryAddress> savedAddresses;
  final int? selectedIdx;
  final bool addingNew;
  final GlobalKey<FormState> formKey;
  final TextEditingController labelCtrl, nameCtrl, phoneCtrl, addressCtrl, cityCtrl, pincodeCtrl;
  final ValueChanged<int> onSelectSaved;
  final VoidCallback onAddNew;
  final VoidCallback onNext;

  const _AddressStep({
    required this.savedAddresses,
    required this.selectedIdx,
    required this.addingNew,
    required this.formKey,
    required this.labelCtrl,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.pincodeCtrl,
    required this.onSelectSaved,
    required this.onAddNew,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (savedAddresses.isNotEmpty) ...[
            const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ...List.generate(savedAddresses.length, (i) {
              final addr = savedAddresses[i];
              final selected = selectedIdx == i && !addingNew;
              return GestureDetector(
                onTap: () => onSelectSaved(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.grey.shade200,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: selected ? AppColors.primary : Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (addr.label.isNotEmpty)
                              Text(addr.label,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            Text(addr.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${addr.address}, ${addr.city} - ${addr.pincode}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(addr.phone,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (selected)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                    ],
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: onAddNew,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: addingNew ? AppColors.primary : Colors.grey.shade200,
                    width: addingNew ? 2 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_location_alt_outlined,
                        color: addingNew ? AppColors.primary : Colors.grey, size: 20),
                    const SizedBox(width: 10),
                    Text('Add New Address',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: addingNew ? AppColors.primary : AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
          if (addingNew || savedAddresses.isEmpty) ...[
            const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Form(
              key: formKey,
              child: Column(
                children: [
                  // Label quick-select chips
                  StatefulBuilder(
                    builder: (ctx, setChipState) => Wrap(
                      spacing: 8,
                      children: ['Home', 'Work', 'Other'].map((lbl) {
                        return ChoiceChip(
                          label: Text(lbl),
                          selected: labelCtrl.text == lbl,
                          onSelected: (_) => setChipState(() => labelCtrl.text = lbl),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field('Label (e.g. Home, Work)', labelCtrl, Icons.label_outline, required: false),
                  const SizedBox(height: 12),
                  _field('Full Name', nameCtrl, Icons.person_outlined),
                  const SizedBox(height: 12),
                  _field('Phone Number', phoneCtrl, Icons.phone_outlined,
                      type: TextInputType.phone),
                  const SizedBox(height: 12),
                  _field('Address', addressCtrl, Icons.home_outlined, maxLines: 2),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field('City', cityCtrl, Icons.location_city_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field('Pincode', pincodeCtrl, Icons.pin_outlined,
                            type: TextInputType.number)),
                  ]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Continue to Payment →', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? type, int maxLines = 1, bool required = true}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
      );
}

// ─── Step 2: Payment ──────────────────────────────────────────────────────────

class _PaymentStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _PaymentStep({
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          _PaymentCard(
            value: 'COD',
            selected: selected,
            icon: Icons.money_rounded,
            title: 'Cash on Delivery',
            subtitle: 'Pay when your order arrives',
            color: AppColors.success,
            onSelect: onSelect,
          ),
          const SizedBox(height: 12),
          _PaymentCard(
            value: 'PREPAY',
            selected: selected,
            icon: Icons.credit_card_rounded,
            title: 'Pay Online',
            subtitle: 'UPI, Debit/Credit Card, Net Banking',
            color: AppColors.primary,
            onSelect: onSelect,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Review Order →', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String value, selected, title, subtitle;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onSelect;

  const _PaymentCard({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Review & Place ───────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final List items;
  final double total, deliveryFee;
  final String address, paymentMethod;
  final bool isPlacing;
  final VoidCallback onBack, onPlace;

  const _ReviewStep({
    required this.items,
    required this.total,
    required this.deliveryFee,
    required this.address,
    required this.paymentMethod,
    required this.isPlacing,
    required this.onBack,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('Delivery To', [
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(address, style: const TextStyle(fontSize: 13, height: 1.4))),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          _section('Payment', [
            Row(
              children: [
                Icon(paymentMethod == 'COD' ? Icons.money_rounded : Icons.credit_card_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(paymentMethod == 'COD' ? 'Cash on Delivery' : 'Online Payment',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          _section('Order Summary', [
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text('${item.product.title} ×${item.quantity}',
                              overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                      Text(Formatters.currency(item.totalPriceInr),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                )),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery', style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  deliveryFee == 0 ? 'FREE' : Formatters.currency(deliveryFee),
                  style: TextStyle(color: deliveryFee == 0 ? AppColors.success : null),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  Formatters.currency(total + deliveryFee),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isPlacing ? null : onBack,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('← Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isPlacing ? null : onPlace,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                  child: isPlacing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Place Order 🎉', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );
}
