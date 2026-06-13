import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String title;
  final String description;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String category;
  final String thumbnail;
  final List<String> images;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.category,
    required this.thumbnail,
    required this.images,
  });

  double get discountedPrice => price * (1 - discountPercentage / 100);
  double get priceInr => price * 83.5;
  double get discountedPriceInr => discountedPrice * 83.5;
  bool get isInStock => stock > 0;

  factory Product.fromDummyJson(Map<String, dynamic> json) => Product(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
        rating: (json['rating'] ?? 0).toDouble(),
        stock: json['stock'] ?? 0,
        category: json['category'] ?? '',
        thumbnail: json['thumbnail'] ?? '',
        images: List<String>.from(json['images'] ?? [json['thumbnail'] ?? '']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'discountPercentage': discountPercentage,
        'rating': rating,
        'stock': stock,
        'category': category,
        'thumbnail': thumbnail,
        'images': images,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product.fromDummyJson(map);

  @override
  List<Object?> get props => [id];
}
