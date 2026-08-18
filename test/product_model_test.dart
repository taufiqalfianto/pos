import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/product/data/model/product_model.dart';

void main() {
  group('ProductModel', () {
    const product = ProductModel(
      id: 'p1',
      name: 'Kopi',
      price: 15000,
      imagePath: 'kopi.jpg',
      stock: 10,
      categoryId: 'food',
    );

    test('toMap menghasilkan map yang sesuai', () {
      final map = product.toMap();
      expect(map['id'], 'p1');
      expect(map['name'], 'Kopi');
      expect(map['price'], 15000);
      expect(map['image_path'], 'kopi.jpg');
      expect(map['stock'], 10);
      expect(map['is_synced'], 0);
      expect(map['category_id'], 'food');
    });

    test('fromMap mengembalikan objek yang sama untuk field sebelumnya', () {
      final restored = ProductModel.fromMap({
        'id': 'p1',
        'name': 'Kopi',
        'price': 15000,
        'image_path': 'kopi.jpg',
        'stock': 10,
        'description': '',
        'is_synced': 0,
        'category_id': 'food',
      });
      expect(restored, product);
    });

    test('fromMap menerapkan default saat field opsional tidak ada', () {
      final restored = ProductModel.fromMap({
        'id': 'p2',
        'name': 'Teh',
        'price': 5000,
      });
      expect(restored.imagePath, '');
      expect(restored.stock, 0);
      expect(restored.description, '');
      expect(restored.isSynced, 0);
      expect(restored.categoryId, 'general');
    });

    test('copyWith mengubah field tertentu', () {
      final updated = product.copyWith(stock: 5, isSynced: 1);
      expect(updated.stock, 5);
      expect(updated.isSynced, 1);
      expect(updated.id, product.id);
      expect(updated.name, product.name);
    });

    test('equality menggunakan semua properti', () {
      expect(
        product,
        const ProductModel(
          id: 'p1',
          name: 'Kopi',
          price: 15000,
          imagePath: 'kopi.jpg',
          stock: 10,
          categoryId: 'food',
        ),
      );
      expect(
        product,
        isNot(
          const ProductModel(
            id: 'p2',
            name: 'Teh',
            price: 5000,
            imagePath: '',
          ),
        ),
      );
    });
  });
}