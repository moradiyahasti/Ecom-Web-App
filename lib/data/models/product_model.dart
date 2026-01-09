class Product {
  final int id;
  final String title;
  final String subtitle;
 final double price;
  final double oldPrice;
  final String image;
  final String? badge;
  final int reviews;
  final double rating;
  final bool isTrending;
    final bool isFavorite;


  Product({
    required this.id,
    required this.title,
    required this.subtitle,
     required this.price,
    required this.oldPrice,
    required this.image,
    this.badge,
    required this.reviews,
    required this.rating,
    required this.isTrending,
        required this.isFavorite,

  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']??'',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      // price: json['price'] ?? 0,
      // oldPrice: json['old_price'],
      
      price: double.parse(json['price'].toString()), // 🔹 double parse
      oldPrice: double.parse(json['old_price'].toString()), // 🔹 double parse
      image: json['image'] ?? '',
      badge: json['badge'],
      reviews: json['reviews'] ?? 0,
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString()) ?? 0.0
          : 0.0,
      isTrending: json['is_trending'] ?? false,
            isFavorite: json['is_favorite'] ?? false, // 🔥 KEY LINE

    );
  }
}
