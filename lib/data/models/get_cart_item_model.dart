class GetCartItemMode {
  final int cartId;
  final int productId;
  final String title;
  final String subtitle;
  final double price;
  int quantity;
  final String image;
  final int userID;

  GetCartItemMode({
    required this.cartId,
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.quantity,
    required this.image,
    required this.userID,
  });

  factory GetCartItemMode.fromJson(Map<String, dynamic> json) {
    return GetCartItemMode(
      cartId: json['cart_id'],
      productId: json['product_id'],
      title: json['title'],
      subtitle: json['subtitle'] ?? "",
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'],
      image: json['image'] ?? "",
      userID: json['user_id'],
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $cartId, product: $productId, title: "$title", price: ₹$price, qty: $quantity)';
  }
}
