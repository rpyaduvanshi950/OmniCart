import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/order_model.dart';
import '../../../models/cart_item_model.dart';

final ordersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => OrderModel.fromMap(d.data())).toList());
});

final placeOrderProvider = Provider<Future<String> Function(List<CartItem>, String, String)>((ref) {
  return (items, address, paymentMethod) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final id = const Uuid().v4();
    final total = items.fold<double>(0, (s, i) => s + i.totalPriceInr);
    final order = OrderModel(
      id: id,
      userId: uid,
      items: items,
      totalAmount: total,
      address: address,
      status: OrderStatus.ordered,
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
    );
    await FirebaseFirestore.instance.collection('orders').doc(id).set(order.toMap());
    return id;
  };
});

final allOrdersAdminProvider = StreamProvider<List<OrderModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => OrderModel.fromMap(d.data())).toList());
});
