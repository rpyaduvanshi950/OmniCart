import 'package:equatable/equatable.dart';
import 'cart_item_model.dart';

enum OrderStatus { ordered, packed, shipped, outForDelivery, delivered, cancelled }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.ordered: return 'Ordered';
      case OrderStatus.packed: return 'Packed';
      case OrderStatus.shipped: return 'Shipped';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }

  int get step {
    switch (this) {
      case OrderStatus.ordered: return 0;
      case OrderStatus.packed: return 1;
      case OrderStatus.shipped: return 2;
      case OrderStatus.outForDelivery: return 3;
      case OrderStatus.delivered: return 4;
      case OrderStatus.cancelled: return -1;
    }
  }
}

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final String address;
  final OrderStatus status;
  final DateTime createdAt;
  final String paymentMethod;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'items': items.map((i) => i.toMap()).toList(),
        'totalAmount': totalAmount,
        'address': address,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'paymentMethod': paymentMethod,
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        items: (map['items'] as List? ?? []).map((i) => CartItem.fromMap(i)).toList(),
        totalAmount: (map['totalAmount'] ?? 0).toDouble(),
        address: map['address'] ?? '',
        status: OrderStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => OrderStatus.ordered,
        ),
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
        paymentMethod: map['paymentMethod'] ?? 'COD',
      );

  @override
  List<Object?> get props => [id];
}
