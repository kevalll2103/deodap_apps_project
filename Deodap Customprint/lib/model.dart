class Product {
  final String productId;
  final String productUniqueId;
  final String? productName;
  final String productImage;
  final String createdAt;
  final String fullname;
  final String mobileNumber;

  Product({
    required this.productId,
    required this.productUniqueId,
    required this.productImage,
    required this.createdAt,
    required this.fullname,
    required this.mobileNumber,
    this.productName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      productUniqueId: json['product_unique_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      createdAt: json['created_at'],
      fullname: json['fullname'],
      mobileNumber: json['mobilenumber'],
    );
  }
}
