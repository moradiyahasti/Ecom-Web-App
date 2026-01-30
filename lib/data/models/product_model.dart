import 'dart:convert';

class Product {
  final int id;
  final String title;
  final String subtitle;
  final double price;
  final double oldPrice;
  final String image;
  final List<String> productImages;
  final String badge;
  final int reviews;
  final double rating;
  final bool isTrending;
  final bool isFavorite;
  final int stockQuantity; // 🔥 CHANGED: stock → stockQuantity
  final String category;
  final String type;
  final List<String> sizes;

  Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.oldPrice,
    required this.image,
    this.productImages = const [],
    required this.badge,
    required this.reviews,
    required this.rating,
    this.isTrending = false,
    this.isFavorite = false,
    this.stockQuantity = 0, // 🔥 CHANGED: stock → stockQuantity
    this.category = '',
    this.type = 'Both Hands',
    this.sizes = const ['XS', 'S', 'M', 'L'],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 🔥 Handle product_images
    List<String> images = [];
    if (json['product_images'] != null) {
      if (json['product_images'] is List) {
        images = List<String>.from(json['product_images']);
      }
    }

    if (images.isEmpty && json['image'] != null) {
      images = [json['image'], json['image'], json['image'], json['image']];
    }

    // 🔥 Handle sizes
    List<String> sizesList = ['XS', 'S', 'M', 'L'];
    if (json['sizes'] != null) {
      if (json['sizes'] is String) {
        try {
          sizesList = List<String>.from(jsonDecode(json['sizes']));
        } catch (e) {
          print('Error parsing sizes: $e');
        }
      } else if (json['sizes'] is List) {
        sizesList = List<String>.from(json['sizes']);
      }
    }

    return Product(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',

      // 🔥 FIX: String to double conversion
      price: _parseDouble(json['price']),
      oldPrice: _parseDouble(json['old_price']),
      rating: _parseDouble(json['rating']),

      image: json['image'] ?? '',
      productImages: images,
      badge: json['badge'] ?? '',

      // 🔥 FIX: String to int conversion
      reviews: _parseInt(json['reviews']),
      // 🔥 CHANGED: Parse 'stock_quantity' field (with fallback to 'stock' for backward compatibility)
      stockQuantity: _parseInt(json['stock_quantity'] ?? json['stock']),

      isTrending: json['is_trending'] == true || json['is_trending'] == 1,
      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 1,
      category: json['category'] ?? '',
      type: json['type'] ?? 'Both Hands',
      sizes: sizesList,
    );
  }

  // 🔥 Helper: Safe double parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // 🔥 Helper: Safe int parsing
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'price': price,
      'old_price': oldPrice,
      'image': image,
      'product_images': productImages,
      'badge': badge,
      'reviews': reviews,
      'rating': rating,
      'is_trending': isTrending,
      'is_favorite': isFavorite,
      'stock_quantity': stockQuantity, // 🔥 CHANGED: stock → stock_quantity
      'category': category,
      'type': type,
      'sizes': sizes,
    };
  }

  // 🔥 ADDED: Convenience getter for backward compatibility
  int get stock => stockQuantity;

  // 🔥 ADDED: copyWith method for easy updates
  Product copyWith({
    int? id,
    String? title,
    String? subtitle,
    double? price,
    double? oldPrice,
    String? image,
    List<String>? productImages,
    String? badge,
    int? reviews,
    double? rating,
    bool? isTrending,
    bool? isFavorite,
    int? stockQuantity,
    String? category,
    String? type,
    List<String>? sizes,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      image: image ?? this.image,
      productImages: productImages ?? this.productImages,
      badge: badge ?? this.badge,
      reviews: reviews ?? this.reviews,
      rating: rating ?? this.rating,
      isTrending: isTrending ?? this.isTrending,
      isFavorite: isFavorite ?? this.isFavorite,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      type: type ?? this.type,
      sizes: sizes ?? this.sizes,
    );
  }
}
