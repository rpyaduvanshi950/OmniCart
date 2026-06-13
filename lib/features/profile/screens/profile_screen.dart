import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? get _user => FirebaseAuth.instance.currentUser;
  bool _isEditingName = false;
  final _nameCtrl = TextEditingController();
  bool _isSaving = false;
  List<DeliveryAddress> _addresses = [];
  bool _addressesLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _user?.displayName ?? '';
    _loadAddresses();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    if (!mounted) return;
    final raw = (doc.data()?['savedAddresses'] as List?) ?? [];
    setState(() {
      _addresses = raw.map((e) => DeliveryAddress.fromMap(e)).toList();
      _addressesLoaded = true;
    });
  }

  Future<void> _saveAddressesToFirestore() async {
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
      'savedAddresses': _addresses.map((a) => a.toMap()).toList(),
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _isSaving = true);
    try {
      final uid = _user!.uid;
      final storageRef = FirebaseStorage.instance.ref('user_photos/$uid.jpg');
      await storageRef.putFile(File(picked.path));
      final url = await storageRef.getDownloadURL();
      await _user!.updatePhotoURL(url);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'photoUrl': url});
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await _user!.updateDisplayName(name);
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({'displayName': name});
      setState(() => _isEditingName = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showAddressForm({DeliveryAddress? existing, int? index}) async {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final pincodeCtrl = TextEditingController(text: existing?.pincode ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<DeliveryAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'Add Address' : 'Edit Address',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Label (e.g. Home, Work)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter valid phone';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: pincodeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Pincode *',
                            prefixIcon: Icon(Icons.pin_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (v.trim().length < 6) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        DeliveryAddress(
                          label: labelCtrl.text.trim(),
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          city: cityCtrl.text.trim(),
                          pincode: pincodeCtrl.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Save Address'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      if (index != null) {
        _addresses[index] = result;
      } else {
        _addresses.add(result);
      }
    });
    await _saveAddressesToFirestore();
  }

  Future<void> _deleteAddress(int index) async {
    setState(() => _addresses.removeAt(index));
    await _saveAddressesToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('Not logged in'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Login')),
            ],
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAvatarSection(),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 16),
          _buildAddressSection(),
          const SizedBox(height: 16),
          _buildOrdersSection(ordersAsync),
          const SizedBox(height: 16),
          _buildAIToolsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() => Center(
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                  child: _user?.photoURL == null
                      ? Text(
                          (_user?.displayName?.isNotEmpty == true
                                  ? _user!.displayName![0]
                                  : _user?.email?[0] ?? 'U')
                              .toUpperCase(),
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: _isSaving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditingName)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _nameCtrl,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.check, color: AppColors.success), onPressed: _saveName),
                  IconButton(
                      icon: const Icon(Icons.close, color: AppColors.error),
                      onPressed: () => setState(() => _isEditingName = false)),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_user?.displayName ?? 'Set your name',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _isEditingName = true),
                    child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(_user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
            if (_user?.emailVerified == true)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: AppColors.success, size: 14),
                    SizedBox(width: 4),
                    Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _buildInfoSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _infoRow(Icons.email_outlined, 'Email', _user?.email ?? ''),
              _infoRow(
                Icons.calendar_today_outlined,
                'Member since',
                _user?.metadata.creationTime != null ? Formatters.date(_user!.metadata.creationTime!) : 'Unknown',
              ),
            ],
          ),
        ),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ]),
          ],
        ),
      );

  Widget _buildAddressSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: () => _showAddressForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (!_addressesLoaded)
                const Center(child: CircularProgressIndicator())
              else if (_addresses.isEmpty)
                const Text('No saved addresses', style: TextStyle(color: AppColors.textSecondary))
              else
                ...List.generate(_addresses.length, (i) {
                  final addr = _addresses[i];
                  return Card(
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (addr.label.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(addr.label,
                                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                  ),
                                Text(addr.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(addr.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(addr.address, style: const TextStyle(fontSize: 13)),
                                Text('${addr.city} - ${addr.pincode}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                onPressed: () => _showAddressForm(existing: addr, index: i),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () => _deleteAddress(i),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      );

  Widget _buildOrdersSection(AsyncValue ordersAsync) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ordersAsync.when(
                data: (orders) => orders.isEmpty
                    ? const Text('No orders yet', style: TextStyle(color: AppColors.textSecondary))
                    : Column(
                        children: orders
                            .take(3)
                            .map<Widget>((o) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.receipt_outlined, color: AppColors.primary),
                                  title: Text('Order #${o.id.substring(0, 8).toUpperCase()}'),
                                  subtitle: Text(Formatters.date(o.createdAt)),
                                  trailing: Text(Formatters.currency(o.totalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ))
                            .toList(),
                      ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Could not load orders'),
              ),
            ],
          ),
        ),
      );

  Widget _buildAIToolsSection() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _aiToolTile(Icons.smart_toy_outlined, 'AI Chat Assistant', () => context.push('/ai-chat')),
              _aiToolTile(Icons.compare_arrows, 'Product Comparison', () => context.push('/compare')),
              _aiToolTile(Icons.shopping_basket_outlined, 'Grocery Planner', () => context.push('/grocery-planner')),
              _aiToolTile(Icons.card_giftcard_outlined, 'Gift Recommendations', () => context.push('/gift-recommendations')),
            ],
          ),
        ),
      );

  Widget _aiToolTile(IconData icon, String label, VoidCallback onTap) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      );
}
