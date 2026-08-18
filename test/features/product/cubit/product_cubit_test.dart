import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/product/cubit/product_cubit.dart';
import 'package:pos/features/product/data/model/product_model.dart';
import 'package:pos/features/product/repository/product_repository.dart';

class FakeProductRepository extends ProductRepository {
  @override
  Stream<void> get productUpdates => StreamController<void>().stream;

  @override
  Future<List<ProductModel>> getProducts() async {
    return const [
      ProductModel(id: '1', name: 'Kopi', price: 15000, imagePath: '', stock: 10),
    ];
  }

  @override
  Future<void> syncPendingData() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductCubit', () {
    late FakeProductRepository repository;
    late ProductCubit cubit;

    setUp(() {
      repository = FakeProductRepository();
      cubit = ProductCubit(repository);
    });

    tearDown(() => cubit.close());

    test('loadProducts emits Loading then Loaded', () async {
      final expected = [isA<ProductLoading>(), isA<ProductLoaded>()];
      expectLater(cubit.stream, emitsInOrder(expected));
      await cubit.loadProducts();
    });

    test('searchProducts filters by name', () async {
      await cubit.loadProducts();
      cubit.searchProducts('kopi');
      expect(cubit.state, isA<ProductLoaded>());
      final loaded = cubit.state as ProductLoaded;
      expect(loaded.products, hasLength(1));
      expect(loaded.products.first.name, 'Kopi');
    });

    test('syncData emits SyncLoading, SyncSuccess, Loaded', () async {
      final expected = [
        isA<ProductSyncLoading>(),
        isA<ProductSyncSuccess>(),
        isA<ProductLoading>(),
        isA<ProductLoaded>(),
      ];
      expectLater(cubit.stream, emitsInOrder(expected));
      await cubit.syncData();
    });
  });
}