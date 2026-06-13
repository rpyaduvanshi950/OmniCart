import 'package:equatable/equatable.dart';
import 'product_model.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get totalPriceInr => product.discountedPriceInr * quantity;

  CartItem copyWith({Product? product, int? quantity}) =>
      CartItem(product: product ?? this.product, quantity: quantity ?? this.quantity);

  Map<String, dynamic> toMap() => {
        'product': product.toMap(),
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        product: Product.fromMap(map['product']),
        quantity: map['quantity'] ?? 1,
      );

  @override
  List<Object?> get props => [product.id];
}
