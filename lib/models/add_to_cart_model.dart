class AddToCartRequest {
  final int userId;
  final int productId;
  final int quantity;

  AddToCartRequest({
    required this.userId,
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {"user_id": userId, "product_id": productId, "quantity": quantity};
  }
}
