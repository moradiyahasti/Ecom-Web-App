class CartItem {
  final int cartId;
  final int productId;
  final String title;
  final String subtitle;
  final int price;
  final int? oldPrice;
  final String image;
  final int quantity;

  CartItem({
    required this.cartId,
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.price,
    this.oldPrice,
    required this.image,
    required this.quantity,
  });

  // ✅ fromJson
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cart_id'],
      productId: json['product_id'],
      title: json['title'],
      subtitle: json['subtitle'],
      price: json['price'],
      oldPrice: json['old_price'],
      image: json['image'],
      quantity: json['quantity'],
    );
  }

  CartItem copyWith({
    int? cartId,
    int? productId,
    String? title,
    String? subtitle,
    int? price,
    int? oldPrice,
    String? image,
    int? quantity,
  }) {
    return CartItem(
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      image: image ?? this.image,
      quantity: quantity ?? this.quantity,
    );
  }
}
