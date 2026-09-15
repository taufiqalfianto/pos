import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/product/data/model/product_model.dart';
import 'package:pos/features/product/screen/product_screen.dart';

ProductModel _product(String name, {String? category, String id = 'general'}) =>
    ProductModel(
      id: name,
      name: name,
      price: 1000,
      imagePath: '',
      categoryId: id,
      categoryName: category,
    );

void main() {
  test('produk dikelompokkan per kategori, kunci terurut alfabetis', () {
    final grouped = groupProductsByCategory([
      _product('Kopi', category: 'Minuman', id: 'minuman'),
      _product('Roti', category: 'Makanan', id: 'makanan'),
      _product('Teh', category: 'Minuman', id: 'minuman'),
      _product('Gula', category: 'Umum'),
    ]);

    expect(grouped.keys.toList(), ['Makanan', 'Minuman', 'Umum']);
    expect(grouped['Minuman']!.map((p) => p.name), ['Kopi', 'Teh']);
    expect(grouped['Makanan']!.single.name, 'Roti');
    expect(grouped['Umum']!.single.name, 'Gula');
  });

  test('kategori tanpa nama jatuh ke "Umum", nama kategori lain -> id-nya', () {
    final grouped = groupProductsByCategory([
      _product('Tanpa Kategori'),
      _product('Yatim', category: null, id: 'c-999'),
    ]);

    expect(grouped.keys.toList(), ['Umum', 'c-999']);
    expect(grouped['Umum']!.single.name, 'Tanpa Kategori');
    expect(grouped['c-999']!.single.name, 'Yatim');
  });

  test('daftar kosong menghasilkan peta kosong', () {
    expect(groupProductsByCategory(const []), isEmpty);
  });
}
