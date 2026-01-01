class GetCartItemMode {
  final int cartId;
  final int productId;
  final String title;
  final String subtitle;
  final double price; 
  int quantity; 
  final String image;

  GetCartItemMode({
    required this.cartId,
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.quantity,
    required this.image,
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
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $cartId, product: $productId, title: "$title", price: ₹$price, qty: $quantity)';
  }
}
