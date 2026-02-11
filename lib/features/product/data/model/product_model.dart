class ProductModel {
  final String id;
  final String name;
  final double price;
  final String imagePath;
  final int stock;
  final String description;
  final int isSynced; // 0: False, 1: True
  final String categoryId;
  final String? categoryName;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    this.stock = 0,
    this.description = '',
    this.isSynced = 0,
    this.categoryId = 'general',
    this.categoryName,
  });

  // Konversi dari Map (Database/JSON) ke Object
  factory ProductModel.fromMap(
    Map<String, dynamic> map, {
    String? categoryName,
  }) {
    return ProductModel(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      imagePath: map['image_path'] ?? '',
      stock: map['stock'] ?? 0,
      description: map['description'] ?? '',
      isSynced: map['is_synced'] ?? 0,
      categoryId: map['category_id'] ?? 'general',
      categoryName: categoryName,
    );
  }

  // Konversi dari Object ke Map (untuk Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_path': imagePath,
      'stock': stock,
      'description': description,
      'is_synced': isSynced,
      'category_id': categoryId,
    };
  }

  // Konversi ke JSON untuk API (Dio)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imagePath,
      'stock': stock,
      'description': description,
      'category_id': categoryId,
    };
  }

  ProductModel copyWith({
    String? name,
    double? price,
    String? imagePath,
    int? stock,
    String? description,
    int? isSynced,
    String? categoryId,
    String? categoryName,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      isSynced: isSynced ?? this.isSynced,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }
}
