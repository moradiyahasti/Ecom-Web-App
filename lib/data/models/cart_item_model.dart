class CartItem {
  final int id; 
  final int productId;
  final String title;
  final String image;
  final int price;
  final int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      title: json['title'],
      image: json['image'],
      price: json['price'],
      quantity: json['quantity'],
    );
  }

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      title: title,
      image: image,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}
