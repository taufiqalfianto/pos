import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/helper/app_logger.dart';
import '../data/model/category_model.dart';
import '../repository/category_repository.dart';

// States
abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  const CategoryLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class CategoryCubit extends Cubit<CategoryState> {
  static const _logTag = 'CategoryCubit';
  final CategoryRepository _repository;

  CategoryCubit(this._repository) : super(CategoryInitial());

  Future<void> loadCategories() async {
    AppLogger.info('Load kategori dimulai', tag: _logTag);
    emit(CategoryLoading());
    try {
      final categories = await _repository.getCategories();
      AppLogger.info(
        'Load kategori berhasil: count=${categories.length}',
        tag: _logTag,
      );
      emit(CategoryLoaded(categories));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Load kategori gagal',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      emit(CategoryError('Gagal memuat kategori: $e'));
    }
  }

  Future<void> addCategory(String name) async {
    try {
      final category = CategoryModel(id: const Uuid().v4(), name: name);
      AppLogger.info(
        'Tambah kategori action dimulai: id=${category.id}',
        tag: _logTag,
      );
      await _repository.addCategory(category);
      AppLogger.info(
        'Tambah kategori action berhasil: id=${category.id}',
        tag: _logTag,
      );
      loadCategories();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Tambah kategori action gagal',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      emit(CategoryError('Gagal menambah kategori: $e'));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      AppLogger.info('Hapus kategori action dimulai: id=$id', tag: _logTag);
      await _repository.deleteCategory(id);
      AppLogger.info('Hapus kategori action berhasil: id=$id', tag: _logTag);
      loadCategories();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Hapus kategori action gagal: id=$id',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      emit(CategoryError('Gagal menghapus kategori: $e'));
    }
  }
}
