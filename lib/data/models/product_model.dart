// // class Product {
// //   final int id;
// //   final String title;
// //   final String subtitle;
// //   final double price;
// //   final double oldPrice;
// //   final String image;
// //   final String? badge;
// //   final int reviews;
// //   final double rating;
// //   final bool isTrending;
// //   final bool isFavorite;

// //   Product({
// //     required this.id,
// //     required this.title,
// //     required this.subtitle,
// //     required this.price,
// //     required this.oldPrice,
// //     required this.image,
// //     this.badge,
// //     required this.reviews,
// //     required this.rating,
// //     required this.isTrending,
// //     required this.isFavorite,
// //   });

// //   factory Product.fromJson(Map<String, dynamic> json) {
// //     return Product(
// //       id: json['id'] ?? '',
// //       title: json['title'] ?? '',
// //       subtitle: json['subtitle'] ?? '',

// //       // price: json['price'] ?? 0,
// //       // oldPrice: json['old_price'],
// //       price: double.parse(json['price'].toString()), // 🔹 double parse
// //       oldPrice: double.parse(json['old_price'].toString()), // 🔹 double parse
// //       image: json['image'] ?? '',
// //       badge: json['badge'],
// //       reviews: json['reviews'] ?? 0,
// //       rating: json['rating'] != null
// //           ? double.tryParse(json['rating'].toString()) ?? 0.0
// //           : 0.0,
// //       isTrending: json['is_trending'] ?? false,
// //       isFavorite: json['is_favorite'] ?? false, // 🔥 KEY LINE
// //     );
// //   }
// // }

// import 'dart:convert';

// class Product {
//   final int id;
//   final String title;
//   final String subtitle;
//   final double price;
//   final double oldPrice;
//   final String image;
//   final List<String> productImages; // 🔥 New field
//   final String badge;
//   final int reviews;
//   final double rating;
//   final bool isTrending;
//   final bool isFavorite;
//   final int stock;
//   final String category;
//   final String type;
//   final List<String> sizes; // 🔥 New field

//   Product({
//     required this.id,
//     required this.title,
//     required this.subtitle,
//     required this.price,
//     required this.oldPrice,
//     required this.image,
//     this.productImages = const [],
//     required this.badge,
//     required this.reviews,
//     required this.rating,
//     this.isTrending = false,
//     this.isFavorite = false,
//     this.stock = 0,
//     this.category = '',
//     this.type = 'Both Hands',
//     this.sizes = const ['XS', 'S', 'M', 'L'],
//   });

//   factory Product.fromJson(Map<String, dynamic> json) {
//     // Handle product_images
//     List<String> images = [];
//     if (json['product_images'] != null) {
//       if (json['product_images'] is List) {
//         images = List<String>.from(json['product_images']);
//       }
//     }

//     // If no product_images, use main image 4 times
//     if (images.isEmpty) {
//       images = [
//         json['image'] ?? '',
//         json['image'] ?? '',
//         json['image'] ?? '',
//         json['image'] ?? '',
//       ];
//     }

//     // Handle sizes
//     List<String> sizesList = ['XS', 'S', 'M', 'L'];
//     if (json['sizes'] != null) {
//       if (json['sizes'] is String) {
//         try {
//           sizesList = List<String>.from(jsonDecode(json['sizes']));
//         } catch (e) {
//           print('Error parsing sizes: $e');
//         }
//       } else if (json['sizes'] is List) {
//         sizesList = List<String>.from(json['sizes']);
//       }
//     }

//     return Product(
//       id: json['id'],
//       title: json['title'] ?? '',
//       subtitle: json['subtitle'] ?? '',
//       price: (json['price'] ?? 0).toDouble(),
//       oldPrice: (json['old_price'] ?? 0).toDouble(),
//       image: json['image'] ?? '',
//       productImages: images,
//       badge: json['badge'] ?? '',
//       reviews: json['reviews'] ?? 0,
//       rating: (json['rating'] ?? 0).toDouble(),
//       isTrending: json['is_trending'] ?? false,
//       isFavorite: json['is_favorite'] ?? false,
//       stock: json['stock'] ?? 0,
//       category: json['category'] ?? '',
//       type: json['type'] ?? 'Both Hands',
//       sizes: sizesList,
//     );
//   }
// }

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
  final int stock;
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
    this.stock = 0,
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
      stock: _parseInt(json['stock']),

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
      'stock': stock,
      'category': category,
      'type': type,
      'sizes': sizes,
    };
  }
}
